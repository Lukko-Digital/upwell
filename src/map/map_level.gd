@tool
extends MapLocation
class_name MapLevel

@export var level: PackedScene

@export var label: Label

@export var name_text: String:
	set(value):
		name_text = value
		label.text = value
		
@onready var game: Game = get_tree().get_current_scene()
@onready var level_sprite = get_sprite()

func _on_area_entered(_area: Area2D):
	player.hit_hazard()

func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()

func get_sprite():
	for child in get_children():
		if child is Sprite2D:
			return child
	return null

func visit(entry_number: int) -> void:
	level_sprite = Color.DIM_GRAY
	Global.update_current_location(name)
	game.change_level(level, entry_number)
