extends LocationType

func location_hovered(map_location: MapLocation):
	player.location_hovered(map_location)

func location_unhovered(map_location: MapLocation):
	player.location_unhovered(map_location)

func location_selected(map_location: MapLocation):
	player.location_selected(map_location)

func player_entered(map_location: MapLocation):
	player.location_reached(map_location)