@tool
extends Sprite2D

@export var top_swivel: Sprite2D
@export var following: bool = false
@export var orbitting: bool = false

func _onready():
	rotation = 0

func _process(delta):
	if orbitting:
		rotation = lerp_angle(rotation, -1.5708, delta*4)
		var tween = create_tween()
		tween.tween_property(self, "self_modulate", Color(1,1,1,1), 0.25)
	elif following:
		rotation = top_swivel.rotation
		var tween = create_tween()
		tween.tween_property(self, "self_modulate", Color(1,1,1,0.65), 0.25)
	else:
		rotation = lerp_angle(rotation, 0.0, delta*4)
		var tween = create_tween()
		tween.tween_property(self, "self_modulate", Color(1,1,1,0.65), 0.25)
