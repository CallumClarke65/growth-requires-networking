function SortTowns(towns, companies) {
	// sorted_towns
	// - not_monitored
	//   - [town_id, ...]
	// - contributed
	//   - company_id
	//     - [town_index, ...] (index of town in towns class list)
	local sorted_towns = {
		not_monitored = [],
		contributed = {}
	};

	foreach(company in companies) {
		sorted_towns.contributed[company.id] <- [];
	}

	foreach(index, town in towns) {
		if (!town.is_monitored)
			sorted_towns.not_monitored.append(town.id);
		else if (town.contributor != -1)
			sorted_towns.contributed[town.contributor].append(index);
	}

	return sorted_towns;
}

function GetBiggestPopulationTown(town_list, towns) {
	local biggest_town = null;
	local biggest_town_population = null;

	foreach(index in town_list) {
		local population = GSTown.GetPopulation(towns[index].id);
		if (biggest_town_population == null || population > biggest_town_population) {
			biggest_town_population = population;
			biggest_town = towns[index].id;
		}
	}

	return biggest_town;
}

function FindClosestTown(town_list, town_id) {
	local closest_town = null;
	local closest_town_distance = null;
	local town_location = GSTown.GetLocation(town_id);

	// Create list of towns already subsidised to be ignored
	local subsidies_list = GSSubsidyList();
	subsidies_list.Valuate(GSSubsidy.GetSourceType);
	subsidies_list.KeepValue(1);
	subsidies_list.Valuate(GSSubsidy.GetSourceIndex);
	subsidies_list.KeepValue(town_id);
	subsidies_list.Valuate(GSSubsidy.GetDestinationIndex);
	local ignore_list = GSList();
	foreach(id, value in subsidies_list) {
		ignore_list.AddItem(value, id);
	}

	foreach(town in town_list) {
		local distance = GSTown.GetDistanceManhattanToTile(town, town_location);
		if (!ignore_list.HasItem(town) && (closest_town_distance == null || closest_town_distance > distance)) {
			closest_town_distance = distance;
			closest_town = town;
		}
	}

	return closest_town;
}

function CreateSubsidies(towns, companies) {
	if (GSGameSettings.GetValue("difficulty.subsidy_duration") == 0)
		return;

	local subsidies = {};

	// Sort industries per towns
	local sorted_towns = SortTowns(towns, companies);

	// Find town and cargo subsidies
	foreach(company, town_list in sorted_towns.contributed) {
		subsidies[company] <- {
			town_subsidy = null,
		};

		// Create town subsidy
		local biggest_town_id = GetBiggestPopulationTown(town_list, towns);
		if (biggest_town_id != null) {
			local closest_town_id = FindClosestTown(sorted_towns.not_monitored, biggest_town_id);
			if (closest_town_id != null) {
				subsidies[company].town_subsidy = {
					town_1 = biggest_town_id,
					town_2 = closest_town_id
				};
			}
		}
	}

	// Create subsidies
	foreach(company, subs in subsidies) {
		if (subs.town_subsidy != null) {
			local success = GSSubsidy.Create(
				Helper.GetPAXCargo(),
				GSSubsidy.SPT_TOWN, subs.town_subsidy.town_1,
				GSSubsidy.SPT_TOWN, subs.town_subsidy.town_2);
		}

		if (subs.cargo_subsidy != null) {
			local success = GSSubsidy.Create(
				subs.cargo_subsidy.cargo_id,
				GSSubsidy.SPT_INDUSTRY, subs.cargo_subsidy.providing_industry_id,
				GSSubsidy.SPT_INDUSTRY, subs.cargo_subsidy.accepting_industry_id);
		}
	}
}