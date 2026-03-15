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
		GSTown.SetText(this.id, TownBoxText());
		this.initialized = true;
		return;
	}

	Log.Info("MonthlyManageTown " + GSTown.GetName(this.id), Log.LVL_INFO);

	/*
	if (this.allowGrowth) {
		GSTown.SetGrowthRate(this.id, this.tgr_average);
	} else {
		GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
	}
		*/

	//this.UpdateSignText();
	GSTown.SetText(this.id, this.TownBoxText());
}

function GoalTown::GetDeliveredCargoTotals()
{
    local cargo_strings = [
        "BEER",
        "GOOD",
        "FOOD",
        "BDMT",
        "PETR"
    ];

    local totals = {};
    local total_all = 0;

    foreach (c in cargo_strings) {
		local cargo_total = 0;
        for (local cid = GSCompany.COMPANY_FIRST; cid <= GSCompany.COMPANY_LAST; cid++) {
        	if (GSCompany.ResolveCompanyID(cid) == GSCompany.COMPANY_INVALID) {
				continue;
			}
			local company_supplied = GSCargoMonitor.GetTownDeliveryAmount(cid, GetCargoIDFromLabel(c), this.id, true);
            cargo_total += company_supplied < 0 ? 0 : company_supplied;
		}
        totals[c] <- cargo_total;
        total_all += cargo_total;
    }

    totals["TOTAL"] <- total_all;
    return totals;
}

function GoalTown::TownBoxText()
{
    local t = GSTown.GetName(this.id);

    local cargo = this.GetDeliveredCargoTotals();

	local cargo_strings = [
        "BEER",
        "GOOD",
        "FOOD",
        "BDMT",
        "PETR"
    ];

	local text = GSText(GSText.STR_FULL_DISPLAY);
	text.AddParam(GSText(GSText.STR_DELIVERY_HISTORY));
	text.AddParam(GSText(GSText["STR_DELIVERY_TOTAL"], cargo["TOTAL"]));


	foreach (c in cargo_strings) {
		text.AddParam(GSText(GSText["STR_DELIVERY_" + c], cargo[c]));
	}

    return text;
}

/*
Cargo Goal: 50/240

Growth limit: 1000 (X cargos provided)

Delivery History (6 months):
Total - 50/48/27/73/0/0
Alcohol - ✓X✓✓✓✓
Goods - ✓✓✓✓✓✓
Food - ✓X✓✓✓✓
Building Materials - XXXXXX
Petrol - ✓X✓X✓X
*/


/*
Population: X Houses: Y
Passengers last month: X max: Y
Mail last month: X max: Y
Town is NOT growing

Connect a passenger service to X to enable growth
*/

/*
Population: X Houses: Y
Passengers last month: X max: Y
Mail last month: X max: Y
Town is NOT growing

Place X's HQ to enable growth mechanics
*/

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

function GoalTown::UpdateSignTexxt() {
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

	GSTown.SetText(this.id, this.TownBoxText());
}


function GoalTown::UpdateTownText(info_mode) {
	GSTown.SetText(this.id, this.TownBoxText());
}

function GetCargoIDFromLabel(label)
{
    local cargos = GSCargoList();

    for (local c = cargos.Begin(); !cargos.IsEnd(); c = cargos.Next()) {
        if (GSCargo.GetCargoLabel(c) == label) {
            return c;
        }
    }

    return -1;
}