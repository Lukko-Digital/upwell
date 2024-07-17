extends Area2D

## Placeholder for MVP3 so player can spawn on the left, then arrive on the right side subsequently

@export var left: EmptyPod
@export var right: EmptyPod

func _ready() -> void:
	if Global.swap_h32_nuclear_entrances:
		left.is_entrace = false
		left.hider.handle_empty()
		right.is_entrace = true
		right.hider.handle_empty()

func _on_body_entered(_body: Node2D):
	Global.swap_h32_nuclear_entrances = true