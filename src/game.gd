extends Control
class_name Game

@export var map_layer: CanvasLayer

@onready var active_level: Node = $ActiveLevel

func change_level(level: PackedScene):
	var current_level = active_level.get_child(0)
	active_level.remove_child(current_level)
	current_level.queue_free()
	var new_level = level.instantiate()
	active_level.add_child(new_level)
	#map_layer.hide()
