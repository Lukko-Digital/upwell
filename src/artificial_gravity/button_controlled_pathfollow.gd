extends PathFollow2D
## Parent class for one button and two button path follows
class_name ButtonControlledPathFollow

@export var speed: float = 400
@export var line: Line2D

var velocity: Vector2
var last_pos: Vector2

func _ready() -> void:
	loop = false
	for point in get_parent().curve.get_baked_points():
		line.add_point(point)

func _process(delta: float) -> void:
	last_pos = position
	handle_movement(delta)
	velocity = (position - last_pos) / delta

func handle_movement(_delta):
	pass