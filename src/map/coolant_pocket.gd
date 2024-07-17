extends Area2D
class_name CoolantPocket

@export var locked: bool = false

@onready var player: MapPlayer = owner.get_node("MapPlayer")

func _ready() -> void:
	hide()

func _on_area_entered(_area: Area2D):
	player.enter_coolant_pocket()

func _on_area_exited(_area):
	player.exit_coolant_pocket()
