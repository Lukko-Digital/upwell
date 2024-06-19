extends Area2D
class_name ArtificialGravity

const DEFAULT_RADIUS = 322

@onready var glow: Sprite2D = $Glow

var enabled: bool = true

func _ready() -> void:
	add_to_group("AGs")
	glow.scale = Vector2.ONE * $CollisionShape2D.shape.radius / DEFAULT_RADIUS

func enable():
	enabled = true
	queue_redraw()

func disable():
	enabled = false
	queue_redraw()
