extends Area2D
class_name CoolantPocket

@export var level_id: Global.LevelIDs
@export var locked: bool = false

@onready var player: MapPlayer = owner.get_node("MapPlayer")

## UPDATE THIS WITH NEW LEVEL UNLOCK ENUM

func _ready() -> void:
	Global.level_unlocked.connect(level_unlocked)
	hide()

func level_unlocked(level_name: String):
	if locked and level_name == level_id:
		show()

func _on_area_entered(_area: Area2D):
	player.enter_coolant_pocket()
