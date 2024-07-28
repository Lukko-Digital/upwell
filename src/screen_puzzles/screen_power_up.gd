extends Area2D
class_name ScreenPowerUp

@export var power: float = 100

@onready var glow: Sprite2D = $ButtonGlow

func _ready() -> void:
    glow.hide()

func _on_area_entered(_area: Area2D) -> void:
    glow.show()

func _on_area_exited(_area: Area2D) -> void:
    glow.hide()
