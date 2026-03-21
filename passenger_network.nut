/*
 * PassengerNetwork class to represent a network of towns that are connected by passenger transport.
 * Since the aim of GRNE is to encourage players to create networks of towns, we need a way to represent these networks and track which towns are part of which network.
 * Later on, we can use this class to implement features that depend on the network, such as growth rates or cargo goals that are influenced by the presence of a network.
 */
class PassengerNetwork {
	initialized = null; // Boolean for whether the network has been initialized yet
	origin_id = null; // Id of the town where the network started
	town_ids = null; // Array of town ids that are part of the network
	stations = null; // Array of station objects that may or may not be part of the network
	connected_station_ids = null; // Array of station ids that are part of the network (derived from stations array)

	constructor() {
		this.initialized = false;
		this.origin_id = null;
		this.town_ids = {};
		this.stations = [];
		this.connected_station_ids = {};
	}
}

function PassengerNetwork::IsTownInNetwork(town_id) {
	return town_id in this.town_ids;
}

function PassengerNetwork::UpdateStationList() {
	// Pull the global list of all stations
	local station_list = GSStationList(GSStation.STATION_ANY);

	foreach(s, _ in station_list) {
		// Check if already exists
		local exists = false;
		foreach(st in this.stations) {
			if (st.station_id == s) {
				exists = true;
				break;
			}
		}
		if (exists) {
			continue;
		}

		local town_id = GSStation.GetNearestTown(s);

		this.stations.append(Station(s, town_id));
	}
}

function PassengerNetwork::TryAddTown(town_id) {
	// If the town is already in the network, we don't need to do anything
	if (this.IsTownInNetwork(town_id)) {
		Log.Info("Town " + GSTown.GetName(town_id) + " is already in the network, skipping", Log.LVL_INFO);
		this.ConnectTownStations(town_id);
		return;
	}

	// Look for stations in the town that have a passenger rating
	local this_towns_passenger_stations = [];
	foreach(station in this.stations) {
		if(station.town_id != town_id) {
			continue;
		}

		if (!GSStation.HasCargoRating(station.station_id, GetCargoIDFromLabel("PASS"))) {
			// TODO - We could optimise better here using Station.Ignore() to mark stations that
			// will never service passengers so that we don't waste time processing them each month
			continue;
		}

		this_towns_passenger_stations.append(station);
	}

	/*
	if (this_towns_passenger_stations.len() > 0) {
		Log.Info("Passenger stations in town " + GSTown.GetName(town_id) + ": " + this_towns_passenger_stations.len(), Log.LVL_INFO);
	}
		*/

	// Now look for vehicles that service the passenger stations in this town
	// If those vehicles also service stations in the network, then we can add this town to the network
	foreach (s in this_towns_passenger_stations) {
		local vehicles = GSVehicleList_Station(s.station_id);
		foreach(v, _ in vehicles) {
			//Log.Info("Vehicle " + v + " (" + GSVehicle.GetName(v) + ")", Log.LVL_INFO);
			local all_stations__that_v_visits = GSStationList_Vehicle(v)

			foreach(st, _ in all_stations__that_v_visits) {

				Log.Info("Station " + st + " (" + GSStation.GetName(st) + ") is serviced by vehicle " + v + " (" + GSVehicle.GetName(v) + ")", Log.LVL_INFO);
				Log.Info("Is station " + st + " in the network? " + (st in this.connected_station_ids), Log.LVL_INFO);

				if (st in this.connected_station_ids) {
					// We found:
					// - a station in the town that has a passenger rating
					// - a vehicle that services that station
					// - a station that is part of the network that is also serviced by that vehicle
					// Therefore we can add this town to the network

					// First add every station that this vehicle visits to the network's list of stations, and mark them as connected
					foreach(st2, _ in all_stations__that_v_visits) {
						if (!st2 in this.connected_station_ids) {
							Log.Info("Marking station " + GSStation.GetName(st2) + " as connected to the network because it is serviced by vehicle " + GSVehicle.GetName(v) + " which services station " + GSStation.GetName(st) + " that is already in the network", Log.LVL_INFO);
							this.connected_station_ids[st2] <- true;
						}
					}
					//Log.Info("Vehicle " + v + " services station " + st + " which is part of the network, and also services station " + s.station_id + " in town " + GSTown.GetName(town_id) + ", so we can add this town to the network", Log.LVL_INFO);

					this.AddTown(town_id);
					return;
				}
			}
		}
	}
}

function PassengerNetwork::AddTown(town_id) {
	if (!this.IsTownInNetwork(town_id)) {
		this.town_ids[town_id] <- true;
		this.ConnectTownStations(town_id);
		Log.Info("Added town " + GSTown.GetName(town_id) + " to the network", Log.LVL_INFO);
	}
}

function PassengerNetwork::InitFromHQ() {
	Log.Info("Attempting to initialize passenger network from the town where " + GSCompany.GetName(GSCompany.COMPANY_FIRST) + "'s HQ is located...", Log.LVL_INFO);

	// Look for company[0]'s HQ station, and use that as the origin of the network
	local hq_tile = GSCompany.GetCompanyHQ(GSCompany.COMPANY_FIRST)

	if (!GSMap.IsValidTile(hq_tile)) {
		Log.Info(GSCompany.GetName(GSCompany.COMPANY_FIRST) + " HQ location is not valid, has it been placed yet?", Log.LVL_INFO);
		return;
	}

	local town_id = GSTile.GetTownAuthority(hq_tile);

	if (town_id == null) {
		Log.Info(GSCompany.GetName(GSCompany.COMPANY_FIRST) + " HQ is not located in a town, it must be located in a town to initialize the passenger network", Log.LVL_INFO);
		return;
	}

	Log.Info("Initializing passenger network from " + GSCompany.GetName(GSCompany.COMPANY_FIRST) + " HQ in town " + GSTown.GetName(town_id), Log.LVL_INFO);

	this.origin_id = town_id;
	this.town_ids[town_id] <- true;
	this.initialized = true;
	this.ConnectTownStations(town_id);
}

function PassengerNetwork::ConnectTownStations(town_id) {
	foreach(station in this.stations) {
		if (station.town_id == town_id) {
			this.connected_station_ids[station.station_id] <- true;
		}
	}
}