extends Area2D
class_name MapLocation

@export var locked: bool = false

@onready var player: MapPlayer = owner.get_node("MapPlayer")

func _ready() -> void:
	hide()