@tool
extends Node2D

func _process(_delta):
	handle_particles()

func handle_particles():
	for child in get_children():
		var target = child.get_child(0)
		target.modulate = modulate