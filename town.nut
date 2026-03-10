/*
 * For each town in the game, an instance of this class is created.
 * It holds the data related to a specific town.
 */
class GoalTown {
	id = null; // Town id
	sign_id = null; // Id for extra text under town name
	town_goals_cat = null; // Town goals per cargo category
	town_supplied_cat = null; // Last monthly supply per cargo category (for categories: see InitCargoLists())

	allowGrowth = null; // limits growth requirement fulfilled
	initialized = null; // Town is fully initialized

	constructor(town_id, load_town_data) {
		this.id = town_id;

		/* If there isn't saved data for the towns, we
		 * initialize them. Otherwise, we load saved data.
		 */
		if (!load_town_data || this.id >= ::TownDataTable.len()) {
			this.sign_id = -1;
			//this.town_goals_cat = array(::CargoCatNum, 0);
			//this.town_supplied_cat = array(::CargoCatNum, 0);

			this.allowGrowth = false;

			this.DisableOrigCargoGoal();

			// These commands require at least all non-construcion actions during pause allowed
			if (GSGameSettings.GetValue("construction.command_pause_level") >= 1) {
				GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
				//GSTown.SetText(this.id, TownBoxText(false, 0));
				this.initialized = true;
			} else
				this.initialized = false;
		} else {
			this.sign_id = ::TownDataTable[this.id].sign_id;
			this.town_goals_cat = ::TownDataTable[this.id].town_goals_cat;
			this.town_supplied_cat = ::TownDataTable[this.id].town_supplied_cat;

			this.UpdateTownText(GSController.GetSetting("town_info_mode"));
			this.initialized = true;
		}
	}
}

/* Arctic and Tropical climate have specific cargo requirements for
 * town growth. This function is called to disable them.
 */
function GoalTown::DisableOrigCargoGoal() {
	switch (GSGameSettings.GetValue("game_creation.landscape")) {
		case (0): // Temperate
			break;
		case (1): // Arctic
			GSTown.SetCargoGoal(this.id, GSCargo.TE_FOOD, 0);
			break;
		case (2): // Tropical
			if (GSTown.GetCargoGoal(this.id, GSCargo.TE_WATER) != 0) {
				GSTown.SetCargoGoal(this.id, GSCargo.TE_WATER, 0);
				GSTown.SetCargoGoal(this.id, GSCargo.TE_FOOD, 0);
			}
			break;
		case (3): // Toyland
			break;
		default:
			return;
	}
}

/* Function called when saving the game. */
function GoalTown::SavingTownData() {
	/* IMPORTANT: if anything of the saved data changes here, we
	 * need to update the MainClass.save_version flag in MainClass'
	 * constructor.
	 */
	local town_data = {};
	town_data.sign_id <- this.sign_id;
	town_data.contributor <- this.contributor;
	town_data.max_population <- this.max_population;
	town_data.is_monitored <- this.is_monitored;
	town_data.allowGrowth <- this.allowGrowth;
	town_data.last_delivery <- this.last_delivery;
	town_data.town_goals_cat <- this.town_goals_cat;
	town_data.town_supplied_cat <- this.town_supplied_cat;
	town_data.town_stockpiled_cat <- this.town_stockpiled_cat;
	town_data.tgr_array <- this.tgr_array;
	town_data.limit_transported <- this.limit_transported;
	town_data.limit_delay <- this.limit_delay;
	town_data.cargo_hash <- this.cargo_hash;
	return town_data;
}

/* Main town management function. Called each month. */
function GoalTown::MonthlyManageTown() {
	// Finish initialization of the town
	if (!this.initialized) {
		GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
		GSTown.SetText(this.id, TownBoxText(false, 0));
		this.initialized = true;
		return;
	}

	Log.Info("MonthlyManageTown " + GSTown.GetName(this.id), Log.LVL_INFO);

	/*
	local sum_goals = 0;
	local goal_diff = 0;
	local goal_diff_percent = 0.0;
	local cur_pop = GSTown.GetPopulation(this.id);
	local parsed_cat = 0;   // index of parsed category
	local new_town_growth_rate = null;
	// Defining difficulty and calculation factors
	local d_factor = GSController.GetSetting("goal_scale_factor") / 100.0;
	local g_factor = GSController.GetSetting("town_growth_factor");
	local e_factor = GSController.GetSetting("exponentiality_factor");
	local sup_imp_part = GSController.GetSetting("supply_impacting_part") / 100.0;
	local lowest_tgr = GSController.GetSetting("lowest_town_growth_rate");
	local allow_0_days_growth = GSController.GetSetting("allow_0_days_growth");
	// Clearing the arrays
	this.town_supplied_cat = array(::CargoCatNum, 0);
	this.town_goals_cat = array(::CargoCatNum, 0);

	// Allow small towns to grow
	if (GSTown.GetPopulation(this.id) < 100) {
	    GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NORMAL);
	    return;
	}

	// Check whether specific cargo goals have been enabled for tropical towns growing over 60
	if (GSGameSettings.GetValue("game_creation.landscape") == 2
	    && GSTown.GetCargoGoal(this.id, GSCargo.TE_WATER) != 0) {
	    GSTown.SetCargoGoal(this.id, GSCargo.TE_WATER, 0);
	    GSTown.SetCargoGoal(this.id, GSCargo.TE_FOOD, 0);
	}

	// Checking whether we should enable or disable town monitoring
	if (!this.CheckMonitoring(this.is_monitored)) return;

	// Calculate supplied cargo
	local companies_supplied = {};
	foreach (index, category in this.town_cargo_cat) {
	    for (local cid = GSCompany.COMPANY_FIRST; cid <= GSCompany.COMPANY_LAST; cid++) {
	        if (GSCompany.ResolveCompanyID(cid) == GSCompany.COMPANY_INVALID)
	            continue;

	        if (!companies_supplied.rawin(cid))
	            companies_supplied[cid] <- [];

	        local category_supplied = 0;
	        foreach (cargo in category) {
	            local cargo_supplied = GSCargoMonitor.GetTownDeliveryAmount(cid, cargo, this.id, true);
	            category_supplied += cargo_supplied < 0 ? 0 : cargo_supplied;
	        }

	        this.town_supplied_cat[index] += category_supplied;
	        companies_supplied[cid].append(category_supplied);
	    }
	}

	// Calculating goals
	for (local i = 0; i < CargoCatNum && cur_pop > ::CargoMinPopDemand[i]; i++) {
	    this.town_goals_cat[i] = max((((cur_pop  - ::CargoMinPopDemand[i]).tofloat() / 1000)
	                    * ::CargoPermille[i]
	                    * d_factor).tointeger(),1);
	}

	// If town's population is too low to calculate a goal, it is set to 1
	if (this.town_goals_cat[0] < 1) this.town_goals_cat[0] = 1;

	// Get max category
	local max_cat = 1;
	while (max_cat < ::CargoCatNum) {
	    if (this.town_goals_cat[max_cat] == 0) break;
	    max_cat++;
	}

	// Calculating global goal and achievement
	for (local i = 0; i < CargoCatNum; ++i) {
	    if (this.town_goals_cat[i] <= 0) {
	        this.town_stockpiled_cat[i] = 0;
	        continue;
	    }

	    this.town_supplied_cat[i] += this.town_stockpiled_cat[i];

	    if (this.town_supplied_cat[i] < this.town_goals_cat[i]) {
	        goal_diff_percent += (this.town_goals_cat[i] - this.town_supplied_cat[i]).tofloat() / (this.town_goals_cat[i] * max_cat).tofloat();
	        this.town_stockpiled_cat[i] = 0;
	    } else {
	        // If stockpiled is bigger than required, we cut off the required part
	        this.town_stockpiled_cat[i] = ((this.town_supplied_cat[i] - this.town_goals_cat[i])
	                         * (1 - ::CargoDecay[i])).tointeger();
	        // Don't stockpile more than: (cargo category) * 10;
	        if (this.town_stockpiled_cat[i] > 300 &&
	            this.town_stockpiled_cat[i] > this.town_goals_cat[i] * 10) {
	            this.town_stockpiled_cat[i] = this.town_goals_cat[i] * 10;
	        }
	    }
	}
	*/

	if (this.allowGrowth) {
		GSTown.SetGrowthRate(this.id, this.tgr_average);
	} else {
		GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
	}

	this.UpdateSignText();
	GSTown.SetText(this.id, this.TownBoxText(true, GSController.GetSetting("town_info_mode"), true));
}


function GoalTown::EternalLove(rating) {
	for (local c = GSCompany.COMPANY_FIRST; c <= GSCompany.COMPANY_LAST; c++) {
		if (!GSTown.IsValidTown(this.id))
			break;
		if (GSCompany.ResolveCompanyID(c) != c)
			continue;
		local cur_rating_class = GSTown.GetRating(this.id, c);
		if (cur_rating_class == GSTown.TOWN_RATING_NONE ||
			cur_rating_class == GSTown.TOWN_RATING_INVALID ||
			cur_rating_class == GSTown.TOWN_RATING_OUTSTANDING)
			continue;
		local cur_rating = GSTown.GetDetailedRating(this.id, c);
		Log.Info("Current/required rating of " + GSTown.GetName(this.id) + ": " + cur_rating + " / " + rating, Log.LVL_DEBUG);
		if (cur_rating < rating)
			GSTown.ChangeRating(this.id, c, rating - cur_rating);
	}
}

function GoalTown::UpdateSignText() {
	// Add a sign by the town to display the current growth
    /*
	if (::SettingsTable.use_town_sign) {
		local sign_text = TownSignText();
		if (GSSign.IsValidSign(this.sign_id)) {
			GSSign.SetName(this.sign_id, sign_text);
		} else {
			this.sign_id = GSSign.BuildSign(GSTown.GetLocation(this.id), sign_text);
		}
	}
    */
}

function GoalTown::RemoveSignText() {
	// Cleaning signs on the map
	if (::SettingsTable.use_town_sign && GSSign.IsValidSign(this.sign_id)) {
		GSSign.RemoveSign(this.sign_id);
		this.sign_id = -1;
	}

	GSTown.SetText(this.id, this.TownBoxText(false, 0));
}


function GoalTown::UpdateTownText(info_mode) {
	GSTown.SetText(this.id, this.TownBoxText(true, info_mode));
}