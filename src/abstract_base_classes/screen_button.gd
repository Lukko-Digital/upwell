extends Area2D
class_name ScreenButton

const SNAP_BREAK_DISTANCE = 100

enum ButtonTypes {NONE, BOOST, UNORBIT, ORBIT}

@export var type = ButtonTypes.NONE

@onready var button_sprite: AnimatedSprite2D = $ButtonSprite
@onready var action_glow: AnimatedSprite2D = $ActionGlow
@onready var hover_glow: Sprite2D = $HoverGlow
@onready var draggable: Area2D = $ScreenDraggable
@onready var line_detection_area: Area2D = $TrajectoryLineDetectionArea

@onready var player: ScreenPlayer = %ScreenPlayer

var selected: bool = false
var placed: bool = false
var offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("ScreenButtons")
	# Signal connections
	draggable.input_event.connect(_on_area_2d_input_event)
	draggable.mouse_entered.connect(_on_mouse_entered)
	draggable.mouse_exited.connect(_on_mouse_exited)
	line_detection_area.area_exited.connect(_on_line_area_exited)
	# Set visuals to default
	button_sprite.play("default")
	action_glow.hide()
	hover_glow.hide()

func _process(_delta):
	if selected:
		position = get_global_mouse_position() + offset
		handle_snap()

func pressed():
	if placed:
		placed = false
		# Update line when picking up button that is placed on the line
		player.update_main_line()

	selected = true
	offset = global_position - get_global_mouse_position()
	button_sprite.play("held")
	action_glow.play("held")
	action_glow.show()

func released():
	selected = false
	if draggable.get_overlapping_areas().is_empty():
		global_position = start_position
	
	if overlapping_trajectory_line():
		# Placed on line
		placed = true
		player.update_main_line()
		button_sprite.play("placed")
		action_glow.play("placed")
		action_glow.show()
	else:
		# Not placed on line
		snap_home()

func sort_closest(a: Vector2, b: Vector2):
	var distance_to = func(point: Vector2):
		return global_position.distance_squared_to(point)
	return distance_to.call(a) < distance_to.call(b)

func handle_snap():
	if not overlapping_trajectory_line():
		return
	
	var snap_point = find_snap_point()
	
	if (global_position + offset).distance_to(snap_point) < SNAP_BREAK_DISTANCE:
		# Snap
		global_position = snap_point
		player.update_new_action_line()
	else:
		# Break snap
		player.clear_new_action_line()

## Find the closest point on the line to snap to
func find_snap_point() -> Vector2:
	var line: Line2D = player.trajectory_line
	var points = Array(line.points)
	points = points.map(func(point): return point + line.global_position)
	points.sort_custom(sort_closest)
	return points.front()

func snap_home():
	global_position = start_position
	button_sprite.play("default")
	action_glow.hide()
	if placed:
		placed = false
		# This is in order to update the lines when the reset button is pressed
		player.update_main_line()
		player.clear_new_action_line()

## Returns true if overlapping the main trajectory line, otherwise null
func overlapping_trajectory_line() -> bool:
	for area in line_detection_area.get_overlapping_areas():
		if area is TrajectoryLineArea:
			return true
	return false

func _on_mouse_entered() -> void:
	hover_glow.show()

func _on_mouse_exited() -> void:
	hover_glow.hide()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	):
		pressed()

func _input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		not event.pressed
	):
		if selected:
			released()

func _on_line_area_exited(_area: Area2D):
	if not selected:
		snap_home()