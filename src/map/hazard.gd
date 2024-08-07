extends Area2D
class_name Hazard

@export var locked: bool = false

@onready var player: MapPlayer = owner.get_node("MapPlayer")

func _ready() -> void:
	hide()

func _on_area_entered(_area: Area2D):
	player.hit_hazard()
