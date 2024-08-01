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

# State variables
var selected: bool = false
var snapped_to_line: bool = false
var placed: bool = false

## The offset from the center of the button where the mouse picked it up
var offset: Vector2 = Vector2.ZERO

var start_position: Vector2 = Vector2.ZERO

## ------------------------------ CORE ------------------------------

func _ready():
	add_to_group("ScreenButtons")
	# Signal connections
	draggable.input_event.connect(_on_area_2d_input_event)
	draggable.mouse_entered.connect(_on_mouse_entered)
	draggable.mouse_exited.connect(_on_mouse_exited)
	player.main_line_updated.connect(_on_main_line_updated)
	area_exited.connect(_on_area_exited)
	# Set visuals to default
	button_sprite.play("default")
	action_glow.hide()
	hover_glow.hide()

func _process(_delta):
	if selected:
		position = get_global_mouse_position() + offset
		handle_snap()

## ------------------------------ PICKING ------------------------------

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
	
	if snapped_to_line:
		# Placed on line
		placed = true
		player.update_main_line()
		button_sprite.play("placed")
		action_glow.play("placed")
		action_glow.show()
	else:
		# Not placed on line
		snap_home()

## ------------------------------ SNAPPING ------------------------------

func handle_snap():
	if not overlapping_trajectory_line():
		return
	
	var snap_point: Vector2 = find_snap_point()
	var point_state: DiscreteScreenPuzzleState = get_point_state(snap_point)
	
	if (
		(global_position + offset).distance_to(snap_point) < SNAP_BREAK_DISTANCE and
		snap_conditions_satisfied(point_state)
	):
		# Snap
		snapped_to_line = true
		global_position = snap_point
		player.update_new_action_line()
	else:
		# Break snap
		snapped_to_line = false
		player.clear_new_action_line()

func sort_closest(a: Vector2, b: Vector2):
	var distance_to = func(point: Vector2):
		return global_position.distance_squared_to(point)
	return distance_to.call(a) < distance_to.call(b)

## Find the closest point on the line to snap to
func find_snap_point() -> Vector2:
	var line: Line2D = player.trajectory_line
	var points = Array(line.points)
	points = points.map(func(point): return point + line.global_position)
	points.sort_custom(sort_closest)
	return points.front()

func get_point_state(point: Vector2) -> DiscreteScreenPuzzleState:
	var point_local = point - player.trajectory_line.global_position
	if player.point_states.has(point_local):
		return player.point_states[point_local]
	return null

func snap_conditions_satisfied(
	point_state: DiscreteScreenPuzzleState,
	ignore_ag_condition: bool = false
) -> bool:
	if point_state == null:
		return false
	if (not ignore_ag_condition) and (not point_state.in_ag):
		return false
	match type:
		ButtonTypes.ORBIT:
			return not point_state.orbiting
		ButtonTypes.UNORBIT:
			return point_state.orbiting
		ButtonTypes.BOOST:
			return point_state.orbiting
		_:
			return false

## Called on placed buttons when line is updated. Check if button is still at
## a valid point on the line. If it isn't snap home.
## The button is assumed to still be on the line because if it wasn't it would
## have snapped home due to [_on_area_exited]
func check_still_valid():
	var closest_point: Vector2 = find_snap_point()
	# Backtrack until reaching a point that doesn't overlap the button.
	# This prevents the issue of a button causing its own snap condition to not
	# be satisfied, i.e. an orbit button sees a point state with orbiting as
	# true, but that's only because the orbit button itself is causing orbiting
	# to be true.
	var backtrack_point = closest_point - player.trajectory_line.global_position
	var point_state: DiscreteScreenPuzzleState = player.point_states[backtrack_point]
	# Should only need to backtrack 1 or 2 points, depending on [player.SPACING]
	while self in point_state.overlapping_areas:
		# To prevent going infinite
		if backtrack_point == Vector2.ZERO:
			break
		backtrack_point = point_state.previous_point
		point_state = player.point_states[backtrack_point]
	# AGs are ignored when checking conditions due to the scenario of a button
	# being placed right on the edge of an AG, causing the backtrack point to
	# be outside of the AG. The button is assumed to already be in an AG because
	# it couldn't have been placed otherwise.
	if not snap_conditions_satisfied(point_state, true):
		snap_home()

func snap_home():
	global_position = start_position
	button_sprite.play("default")
	action_glow.hide()
	if placed:
		placed = false
		# This is in order to update the lines when the reset button is pressed
		player.update_main_line()
		player.clear_new_action_line()

## ------------------------------ HELPER ------------------------------

## Returns true if overlapping the main trajectory line, otherwise null
func overlapping_trajectory_line() -> bool:
	for area in line_detection_area.get_overlapping_areas():
		if area is TrajectoryLineArea:
			return true
	return false

## ------------------------------ SIGNAL RECEIVERS ------------------------------

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

func _on_main_line_updated():
	if placed:
		check_still_valid()

func _on_area_exited(area: Area2D):
	if area is TrajectoryLineArea:
		snap_home()