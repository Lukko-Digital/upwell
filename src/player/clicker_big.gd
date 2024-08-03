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
	elif following:
		rotation = top_swivel.rotation
	else:
		rotation = lerp_angle(rotation, 0.0, delta*4)
