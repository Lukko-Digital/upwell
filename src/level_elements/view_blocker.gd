@tool
extends Node2D
class_name ViewBlocker

@export var sprites: Array[Sprite2D]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for sprite in sprites:
		sprite.global_position = global_position
		sprite.rotation = rotation
		sprite.visible = visible
		sprite.scale = scale
		sprite.modulate = modulate
	pass
