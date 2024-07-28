extends MapLocation
class_name CoolantPocket

func _on_area_entered(_area: Area2D):
	player.enter_coolant_pocket()

func _on_area_exited(_area):
	player.exit_coolant_pocket()
