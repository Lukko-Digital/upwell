extends Area2D
class_name Hazard

@export var level_id: Global.LevelIDs
@export var locked: bool = false

@onready var player: MapPlayer = owner.get_node("MapPlayer")

func _ready() -> void:
	Global.level_unlocked.connect(level_unlocked)
	hide()

func level_unlocked(level_name: Global.LevelIDs):
	if locked and level_name == level_id:
		show()

func _on_area_entered(_area: Area2D):
	player.hit_hazard()
