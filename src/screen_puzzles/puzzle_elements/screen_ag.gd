@tool
extends Area2D
class_name ScreenAG

const DEFAULT_RADIUS = 365

@onready var glow: Sprite2D = $Glow

func _ready() -> void:
	set_glow_size()

func _process(_delta):
	if Engine.is_editor_hint():
		set_glow_size()

func set_glow_size():
	glow.scale = Vector2.ONE * radius() / DEFAULT_RADIUS

func radius() -> float:
	return $CollisionShape2D.shape.radius