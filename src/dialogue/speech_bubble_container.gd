@tool
extends MarginContainer

func _process(_delta: float) -> void:
	position.y = -size.y * scale.y + 20
	size.y = 0