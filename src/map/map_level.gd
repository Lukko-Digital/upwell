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
@onready var gravity_area = $Gravity

func _on_area_entered(_area: Area2D):
	player.hit_hazard()

func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()

func _process(_delta):
	if not Engine.is_editor_hint():
		gravity_area.visible = Global.pod_has_clicker

func visit(entry_number: int) -> void:
	$Sprite2D.modulate = Color.DIM_GRAY
	Global.update_current_location(name)
	game.change_level(level, entry_number)
