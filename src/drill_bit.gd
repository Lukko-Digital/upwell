extends RigidBody3D

var has_been_stuck = false

func _on_wall_detection_area_body_entered(_body: Node3D) -> void:
	if not has_been_stuck:
		set_deferred("freeze", true)
		has_been_stuck = true