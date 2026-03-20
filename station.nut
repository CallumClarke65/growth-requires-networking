/*
 * PassengerNetwork class to represent a network of towns that are connected by passenger transport.
 * Since the aim of GRNE is to encourage players to create networks of towns, we need a way to represent these networks and track which towns are part of which network.
 * Later on, we can use this class to implement features that depend on the network, such as growth rates or cargo goals that are influenced by the presence of a network.
 */
class Station {
	station_id = null; // GSStation id
	town_id = null; // Id of the town this station is in

	constructor(station_id, town_id) {
		this.station_id = station_id;
		this.town_id = town_id;
	}
}
