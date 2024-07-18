@tool
extends MarginContainer

func _process(_delta: float) -> void:
	position.y = -size.y * scale.y + 18
	size.y = 0