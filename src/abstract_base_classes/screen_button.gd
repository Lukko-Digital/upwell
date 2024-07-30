extends Area2D
class_name ScreenButton

const SNAP_BREAK_DISTANCE = 100

enum ButtonTypes {NONE, BOOST, UNORBIT, ORBIT}

@export var type = ButtonTypes.NONE
@export var disabled: bool = false

# @export var normal_texture: Texture2D
# @export var held_texture: Texture2D
# @export var released_texture: Texture2D

@onready var button_sprite: AnimatedSprite2D = $ButtonSprite
@onready var button_glow: AnimatedSprite2D = $ButtonGlow
@onready var draggable: Area2D = $ScreenDraggable
@onready var line_detection_area: Area2D = $TrajectoryLineDetectionArea

var selected: bool = false
var placed: bool = false
var offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready():
	draggable.input_event.connect(_on_area_2d_input_event)
	draggable.mouse_entered.connect(_on_mouse_entered)
	draggable.mouse_exited.connect(_on_mouse_exited)

	line_detection_area.area_exited.connect(_on_line_area_exited)

	button_glow.hide()
	button_sprite.play("default")
	button_glow.play("default")
	
	if disabled:
		draggable.set_deferred("input_pickable", false)
		modulate = Color("727272")

func _process(_delta):
	if selected:
		position = get_global_mouse_position() + offset
		handle_snap()

func pressed():
	if placed:
		placed = false
		var line_area: TrajectoryLineArea = overlapping_trajectory_line()
		if line_area != null:
			line_area.screen_player.update_main_line()

	selected = true
	offset = global_position - get_global_mouse_position()
	button_sprite.play("held")
	button_glow.play("held")

func released():
	selected = false
	if draggable.get_overlapping_areas().is_empty():
		global_position = start_position
	
	var line_area: TrajectoryLineArea = overlapping_trajectory_line()
	if line_area != null:
		# Placed on line
		placed = true
		line_area.screen_player.update_main_line()
		button_sprite.play("placed")
		button_glow.play("placed")

	else:
		# Not placed on line
		snap_home()

func sort_closest(a: Vector2, b: Vector2):
	var distance_to = func(point: Vector2):
		return global_position.distance_squared_to(point)
	return distance_to.call(a) < distance_to.call(b)

func handle_snap():
	var line_area: TrajectoryLineArea = overlapping_trajectory_line()
	if line_area == null:
		return
	
	var line: Line2D = line_area.trajectory_line

	# Determine point to snap to
	var points = Array(line.points)
	points = points.map(func(point): return point + line.global_position)
	points.sort_custom(sort_closest)
	var closest_point = points[0]

	if (global_position + offset).distance_to(closest_point) < SNAP_BREAK_DISTANCE:
		# Snap
		global_position = closest_point
		line_area.screen_player.update_new_action_line()
	else:
		# Break snap
		line_area.screen_player.clear_new_action_line()

func snap_home():
	if selected:
		return
	placed = false
	global_position = start_position
	button_sprite.play("default")
	button_glow.play("default")

## Returns the [TrajectoryLineArea] if overlapping, otherwise null
func overlapping_trajectory_line():
	for area in line_detection_area.get_overlapping_areas():
		if area is TrajectoryLineArea:
			return area
	return null

func _on_mouse_entered() -> void:
	button_glow.show()

func _on_mouse_exited() -> void:
	button_glow.hide()

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
	snap_home()