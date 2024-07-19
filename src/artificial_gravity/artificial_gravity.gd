@tool
extends Area2D
class_name ArtificialGravity

@export var DEFAULT_RADIUS = 450

# Animation
const DEATH_TIME = 0.3
const REGROW_TIME = 1
const DEATH_TRANSITION = Tween.TRANS_CUBIC
const REGROW_TRANSITION = Tween.TRANS_CUBIC

enum AGTypes {PUSHPULL, ORBIT, FUNNEL, ONLYUP}

## The time it takes from disabling the AG to it starting to regrow
@export var regen_wait_time: float = 1.0
@export var type: AGTypes = AGTypes.PUSHPULL

@onready var glow: Sprite2D = %Glow
@onready var regen_timer: Timer = %RegenTimer

var enabled: bool = true

var standard_scale: Vector2

func _ready() -> void:
	add_to_group("AGs")
	standard_scale = Vector2.ONE * radius() / DEFAULT_RADIUS
	glow.scale = standard_scale

func _process(_delta):
	if Engine.is_editor_hint():
		glow.scale = Vector2.ONE * radius() / DEFAULT_RADIUS

func enable():
	enabled = true
	glow.scale = standard_scale
	glow.modulate = Color(Color.WHITE, 1.0)

func disable():
	enabled = false
	glow.modulate = Color(Color.WHITE, 0.5)
	regen_timer.start(regen_wait_time)
	death_animation()

func death_animation():
	var tween = create_tween()
	tween.tween_property(glow, "scale", Vector2.ZERO, DEATH_TIME).set_trans(DEATH_TRANSITION)

func regen():
	var tween = create_tween()
	tween.tween_property(glow, "scale", standard_scale, REGROW_TIME).set_trans(REGROW_TRANSITION)
	await tween.finished
	enable()

func velocity() -> Vector2:
	var parent = get_parent()
	if parent is ButtonControlledPathFollow:
		return parent.velocity
	return Vector2.ZERO

func radius() -> float:
	return $CollisionShape2D.shape.radius

func _on_regen_timer_timeout() -> void:
	regen()
