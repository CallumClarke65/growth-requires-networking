/*
 * CargoList class to represent the list of cargos that will govern town growth
 */
class CargoList {
	initialized = null; // Boolean for whether the network has been initialized yet
	cargo_ids = null; // hash set of cargo ids we will use for growth goals

	constructor() {
		this.initialized = false;
		this.cargo_ids = {};
	}
}

desired_cargo_list <- [
	"BEER", // Alcohol
	"GOOD", // Goods
	"FOOD", // Food
	"BDMT", // Building Materials
	"PETR" // Petrol
];

function CargoList::Init() {
	Log.Info("Initializing cargo list...", Log.LVL_INFO);

	foreach(cargo_name in desired_cargo_list) {
		local id = GetCargoIDFromLabel(cargo_name);
		if (id == -1) {
			Log.Info("Desired cargo " + cargo_name + " is not present in this game", Log.LVL_INFO);
			continue;
		}
		this.cargo_ids[cargo_name] <- id;
	}

	this.initialized = true;
	return true;
}

function CargoList::GetCount() {
    local count = 0;
    foreach (k, v in this.cargo_ids) {
        count++;
    }
    return count;
}

function CargoList::ToString() {
    local result = "";
    local first = true;

    foreach (cargo_name, cargo_id in this.cargo_ids) {
        if (!first) {
            result += ", ";
        }
        result += cargo_name; // or cargo_id if you prefer IDs
        first = false;
    }

    return result;
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