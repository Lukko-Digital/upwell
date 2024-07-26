extends Node2D
class_name PodDoor

@onready var pod_door: Sprite2D = $PodDoor
@onready var pod_light: Sprite2D = $PodLight
@onready var outside_ray: RayCast2D = $RayCast2D

enum DoorFrames {
	OPEN, CLOSED
}

func _process(_delta: float) -> void:
	if outside_ray.is_colliding():
		# Close
		pod_light.hide()
		pod_door.frame = DoorFrames.CLOSED
	else:
		# Open
		pod_light.show()
		pod_door.frame = DoorFrames.OPEN