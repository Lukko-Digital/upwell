@tool
extends MapLocation
class_name MapLevel

@export var level: PackedScene
@export_file("*.txt") var log_file
@export var name_text: String:
	set(value):
		name_text = value
		name_label.text = value
@export var name_label: Label

@onready var game: Game = get_tree().get_current_scene()
@onready var level_sprite = get_sprite()

var log_dict: Dictionary

func _on_area_entered(_area: Area2D):
	player.hit_hazard()

func _ready() -> void:
	if log_file:
		log_dict = LogFileParser.parse(log_file)
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
