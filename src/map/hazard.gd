extends MapLocation
class_name Hazard

func _on_area_entered(_area: Area2D):
	player.hit_hazard()
