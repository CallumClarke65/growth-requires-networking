/*
 * For each town in the game, an instance of this class is created.
 * It holds the data related to a specific town.
 */
class GoalTown {
	id = null; // Town id
	sign_id = null; // Id for extra text under town name
	cargo_goal = null; // Goal amount for growth next month
	total_cargo_supplied_6_months = null; // Array with the amount of cargo supplied in the last 6 months
	types_cargo_supplied_6_months = null; // Array with the types of cargo supplied in the last 6 months
	types_cargo_count = null; // Number of unique final products supplied last month
	growthLimit = null; // Max population we can grow to with the current variety of cargo supplied

	initialized = null; // Town is fully initialized

	constructor(town_id, load_town_data) {
		this.id = town_id;

		/* If there isn't saved data for the towns, we
		 * initialize them. Otherwise, we load saved data.
		 */
		if (!load_town_data || this.id >= ::TownDataTable.len()) {
			this.sign_id = -1;

			this.DisableOrigCargoGoal();

			this.SetCargoGoal();
			this.total_cargo_supplied_6_months = [0, 0, 0, 0, 0, 0];
			this.types_cargo_supplied_6_months = {};
			this.types_cargo_count = 0;
			this.growthLimit = 0;

			local cargo_strings = [
				"BEER",
				"GOOD",
				"FOOD",
				"BDMT",
				"PETR"
			];

			foreach(c in cargo_strings) {
				this.types_cargo_supplied_6_months[c] <- [false, false, false, false, false, false];
			}

			// These commands require at least all non-construcion actions during pause allowed
			if (GSGameSettings.GetValue("construction.command_pause_level") >= 1) {
				GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
				//GSTown.SetText(this.id, TownBoxText(false, 0));
				this.initialized = true;
			} else
				this.initialized = false;
		} else {
			this.sign_id = ::TownDataTable[this.id].sign_id;
			this.cargo_goal = ::TownDataTable[this.id].cargo_goal;
			this.total_cargo_supplied_6_months = ::TownDataTable[this.id].total_cargo_supplied_6_months;
			this.growthLimit = ::TownDataTable[this.id].growthLimit;

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

	// First get this month's stats
	this.UpdateDeliveredCargoTotals();

	// Now use the new stats to calculate whether the town should allow growth or not, and update the sign text if needed
	this.DoGrowthCheck();

	// Update the new cargo goal for the next month
	this.SetCargoGoal();

	// Finally, update display
	this.UpdateTownText();
}

function GoalTown::UpdateDeliveredCargoTotals() {
	local cargo_strings = [
		"BEER",
		"GOOD",
		"FOOD",
		"BDMT",
		"PETR"
	];

	// Update the history arrays
	for (local i = 5; i > 0; i--) {
		this.total_cargo_supplied_6_months[i] = this.total_cargo_supplied_6_months[i - 1];
		foreach(c in cargo_strings) {
			this.types_cargo_supplied_6_months[c][i] = this.types_cargo_supplied_6_months[c][i - 1];
		}
	}

	// Loop through each cargo and then each company to get the total amount of cargo delivered to the town in the last month
	local totals = {};
	local total_all = 0;
	foreach(c in cargo_strings) {
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
		types_cargo_supplied_6_months[c][0] = cargo_total > 0;
	}

	this.total_cargo_supplied_6_months[0] = total_all;
}

function GoalTown::DoGrowthCheck() {
	// If there is no passenger network, the town can't grow
	if (!::PassengerNetwork.initialized) {
		GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
		return;
	}

	// If the town is not connected to the passenger network, it can't grow
	if (!::PassengerNetwork.IsTownInNetwork(this.id)) {
		GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
		return;
	}

	local cargo_strings = [
		"BEER",
		"GOOD",
		"FOOD",
		"BDMT",
		"PETR"
	];

	// Check how many unique final products were supplied in the last month
	local unique_cargos = 0;
	foreach(c in cargo_strings) {
		if (this.types_cargo_supplied_6_months[c][0]) {
			unique_cargos++;
		}
	}
	this.types_cargo_count = unique_cargos;

	// Is our growth limited by the number of different cargos supplied?
	switch (unique_cargos) {
		case 0:
			this.growthLimit = GSController.GetSetting("growth_limit_0_cargos");
			break;
		case 1:
			this.growthLimit = GSController.GetSetting("growth_limit_1_cargos");
			break;
		case 2:
			this.growthLimit = GSController.GetSetting("growth_limit_2_cargos");
			break;
		case 3:
			this.growthLimit = GSController.GetSetting("growth_limit_3_cargos");
			break;
		case 4:
			this.growthLimit = GSController.GetSetting("growth_limit_4_cargos");
			break;
		default:
			this.growthLimit = -1; // No growth limit
			break;
	}

	// Did we meet the cargo goal for this month?
	if (this.total_cargo_supplied_6_months[0] < this.cargo_goal) {
		if (unique_cargos == 0 && GSTown.GetPopulation(this.id) < this.growthLimit) {
			GSTown.SetGrowthRate(this.id, GSController.GetSetting("growth_rate"));
			return;
		} else {
			GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
			return;
		}
	}

	// If we are under the growth limit, or growth is not limited, allow growth. Otherwise, disable it.
	if (this.growthLimit == -1 || GSTown.GetPopulation(this.id) < this.growthLimit) {
		GSTown.SetGrowthRate(this.id, GSController.GetSetting("growth_rate"));
		return;
	} else {
		GSTown.SetGrowthRate(this.id, GSTown.TOWN_GROWTH_NONE);
		return;
	}
}

function GoalTown::SetCargoGoal() {
	local cargo_goal_per_thousand = GSController.GetSetting("goal_per_thousand_pop");
	this.cargo_goal = (cargo_goal_per_thousand * GSTown.GetPopulation(this.id)) / 1000;
}

function GoalTown::TownBoxText() {
	// We have three scenarios-
	// 1. There is no passenger network- no growth
	// 2. The town is not connected to the network- no growth
	// 3. The town is in the network- growth mechanics enabled

	// Case 1: no passenger network
	if (!::PassengerNetwork.initialized) {
		return GSText(GSText["STR_NO_NETWORK"], GSCompany.GetName(GSCompany.COMPANY_FIRST));
	}

	// Case 2: town not connected to the network
	if (!::PassengerNetwork.IsTownInNetwork(this.id)) {
		return GSText(GSText["STR_TOWN_NOT_IN_NETWORK"], GSTown.GetName(::PassengerNetwork.origin_id));
	}


	local cargo_strings = [
		"BEER",
		"GOOD",
		"FOOD",
		"BDMT",
		"PETR"
	];

	local text = GSText(GSText.STR_FULL_DISPLAY);

	text.AddParam(GSText(GSText["STR_CARGO_DELIVERED"], this.total_cargo_supplied_6_months[0], this.cargo_goal)); // Cargo Goal: X / Y
	text.AddParam(GSText(GSText["STR_GROWTH_LIMIT"], this.growthLimit, this.types_cargo_count)); // Growth limit: X (Y cargos provided)

	text.AddParam(GSText(GSText.STR_DELIVERY_HISTORY));
	text.AddParam(GSText(GSText["STR_DELIVERY_TOTAL"], this.total_cargo_supplied_6_months[0], this.total_cargo_supplied_6_months[1], this.total_cargo_supplied_6_months[2], this.total_cargo_supplied_6_months[3], this.total_cargo_supplied_6_months[4], this.total_cargo_supplied_6_months[5])); // Total - X/X/X/X/X/X


	foreach(c in cargo_strings) {
		// Translate our boolean values into checkmarks and crossmarks for display
		local cargo_delivered_0 = this.types_cargo_supplied_6_months[c][0] ? GSText.STR_CHECKMARK : GSText.STR_CROSSMARK;
		local cargo_delivered_1 = this.types_cargo_supplied_6_months[c][1] ? GSText.STR_CHECKMARK : GSText.STR_CROSSMARK;
		local cargo_delivered_2 = this.types_cargo_supplied_6_months[c][2] ? GSText.STR_CHECKMARK : GSText.STR_CROSSMARK;
		local cargo_delivered_3 = this.types_cargo_supplied_6_months[c][3] ? GSText.STR_CHECKMARK : GSText.STR_CROSSMARK;
		local cargo_delivered_4 = this.types_cargo_supplied_6_months[c][4] ? GSText.STR_CHECKMARK : GSText.STR_CROSSMARK;
		local cargo_delivered_5 = this.types_cargo_supplied_6_months[c][5] ? GSText.STR_CHECKMARK : GSText.STR_CROSSMARK;

		text.AddParam(
			GSText(GSText["STR_DELIVERY_" + c],
				GSText(cargo_delivered_0),
				GSText(cargo_delivered_1),
				GSText(cargo_delivered_2),
				GSText(cargo_delivered_3),
				GSText(cargo_delivered_4),
				GSText(cargo_delivered_5)
			));
	}

	return text;
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

function GoalTown::UpdateTownText() {
	GSTown.SetText(this.id, this.TownBoxText());
}

function GetCargoIDFromLabel(label) {
	local cargos = GSCargoList();

	for (local c = cargos.Begin(); !cargos.IsEnd(); c = cargos.Next()) {
		if (GSCargo.GetCargoLabel(c) == label) {
			return c;
		}
	}

	return -1;
}