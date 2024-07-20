@tool
extends Node2D
class_name ViewBlocker

@export_range(0, 1000) var amount_of_blur: float = 0:
	set(value):
		material.set("shader_parameter/radius",amount_of_blur)
		amount_of_blur = value

func _ready():
	material = material.duplicate()

func _process(_delta):
	handle_sprites()
	handle_canvas()

func handle_sprites():
	for child in get_children():
		var target = child.get_child(0)
		target.global_position = global_position
		target.rotation = rotation
		target.visible = visible
		target.scale = scale
		target.modulate = modulate
		target.material = material

func handle_canvas():
	for child in get_children():

		var canvas_name = child.get_name()

		if !canvas_name.is_valid_int():
			continue
		
		child.layer = canvas_name.to_int()
		child.follow_viewport_scale = canvas_name.to_float()/10