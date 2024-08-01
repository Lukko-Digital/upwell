@tool
extends Area2D
class_name DialogueStandLocation

@export var disabled: bool = false:
	set(value):
		$CollisionShape2D.disabled = value
		disabled = value