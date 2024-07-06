extends Area2D
class_name ArtificialGravity

const DEFAULT_RADIUS = 450

enum AGTypes {PUSHPULL, ORBIT, FUNNEL, ONLYUP}

@export var type: AGTypes = AGTypes.PUSHPULL

@onready var glow: Sprite2D = $Glow

var enabled: bool = true:
	set(value):
		glow.visible = value
		enabled = value

func _ready() -> void:
	add_to_group("AGs")
	glow.scale = Vector2.ONE * $CollisionShape2D.shape.radius / DEFAULT_RADIUS

func enable():
	enabled = true
	queue_redraw()

func disable():
	enabled = false
	queue_redraw()

func radius() -> float:
	return $CollisionShape2D.shape.radius