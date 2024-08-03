@tool
extends Sprite2D

@export var top_swivel: Sprite2D
@export var following: bool = false
@export var orbitting: bool = false
@export var rotation_offset: float
var target_rotation: float = 0

func _onready():
	rotation = 0

func _process(delta):
	if orbitting:
		target_rotation = lerp_angle(target_rotation, -1.5708, delta * 4)
		tween_modulate(1)
	elif following:
		target_rotation = top_swivel.rotation
		tween_modulate(0.65)
	else:
		target_rotation = lerp_angle(target_rotation, 0.0, delta * 4)
		tween_modulate(0.65)

	rotation = target_rotation + rotation_offset

func tween_modulate(opacity: float):
	var tween = create_tween()
	tween.tween_property(self, "self_modulate", Color(1, 1, 1, opacity), 0.25)