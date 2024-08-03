@tool
extends Sprite2D

@export var clicker_big: Sprite2D

func _process(_delta):
	rotation = clicker_big.rotation
	self_modulate = clicker_big.self_modulate
	get_child(0).self_modulate = clicker_big.get_child(0).self_modulate