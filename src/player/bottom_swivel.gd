@tool
extends Sprite2D

@export var top_swivel: Sprite2D
@export var following: bool = false

func _onready():
	rotation = 0

func _process(delta):
	if following:
		rotation = top_swivel.rotation
	else:
		rotation = lerp_angle(rotation, 0.0, delta*4)
