@tool
extends MarginContainer

## Somewhat arbitrary number, determined by just tweaking the value until speech
## bubbble lines up with nodule, will need change as the scale of various
## elements change
const NODULE_OFFSET = -10

func _process(_delta: float) -> void:
	position.y = -size.y * scale.y + NODULE_OFFSET
	size.y = 0