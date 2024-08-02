@tool
extends Node2D
## Handles the location that buttons start at and snap back to.
## Expects all [ScreenButtons] to be childed to this node
class_name ButtonHomeHandler

const OFFSET = 210
const SEPARATION = 200

@export var puzzle_bar: TextureRect:
	set(value):
		puzzle_bar = value
		update_configuration_warnings()

func _ready() -> void:
	# Wait for container to place puzzle bar
	await get_tree().process_frame
	var i = 0
	for child in get_children():
		if not child is ScreenButton:
			continue
		child.start_position = puzzle_bar.global_position + Vector2(OFFSET + i * SEPARATION, puzzle_bar.size.y / 2)
		child.global_position = child.start_position
		i += 1

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []

	if puzzle_bar == null:
		warnings.append("Missing puzzle bar export")
	
	return warnings
