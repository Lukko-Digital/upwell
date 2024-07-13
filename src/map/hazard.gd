extends Area2D
class_name Hazard

@export var locked_level_name: String

@onready var player: MapPlayer = owner.get_node("MapPlayer")

## UPDATE THIS WITH NEW LEVEL UNLOCK ENUM

func _ready() -> void:
	Global.level_unlocked.connect(level_unlocked)
	if locked_level_name:
		hide()

func level_unlocked(level_name: String):
	if level_name == locked_level_name:
		show()

func _on_area_entered(_area: Area2D):
	player.enter_coolant_pocket()
