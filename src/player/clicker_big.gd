@tool
extends Sprite2D

@export var top_swivel: Sprite2D
@export var following: bool = false
@export var orbitting: bool = false

func _onready():
	rotation = 0

func _process(delta):
	if orbitting:
		rotation = lerp_angle(rotation, -1.5708, delta * 4)
		tween_modulate(1)
	elif following:
		rotation = top_swivel.rotation
		tween_modulate(0.65)
	else:
		rotation = lerp_angle(rotation, 0.0, delta * 4)
		tween_modulate(0.65)

func tween_modulate(opacity: float):
	var tween = create_tween()
	tween.tween_property(self, "self_modulate", Color(1, 1, 1, opacity), 0.25)