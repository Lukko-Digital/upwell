@tool
extends Node2D

func _process(_delta):
	for child in get_children():
		for child2 in child.get_children():
			child2.position = get_parent().position