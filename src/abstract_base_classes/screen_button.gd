extends Area2D
class_name ScreenButton

const SNAP_BREAK_DISTANCE = 100

enum ButtonTypes {NONE, BOOST, UNORBIT, ORBIT}

@export var type = ButtonTypes.NONE
@export var disabled: bool = false

@export var normal_texture: Texture2D
@export var held_texture: Texture2D
@export var released_texture: Texture2D

@onready var button_sprite: Sprite2D = $Sprite2D
@onready var button_glow: Sprite2D = $ButtonGlow
@onready var draggable: Area2D = $ScreenDraggable

var selected: bool = false
var offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready():
	draggable.input_event.connect(_on_area_2d_input_event)
	draggable.mouse_entered.connect(_on_mouse_entered)
	draggable.mouse_exited.connect(_on_mouse_exited)

	# area_shape_entered.connect(_on_area_shape_entered)

	button_glow.hide()
	button_glow.modulate = Color(Color.WHITE, 0.5)
	if disabled:
		draggable.set_deferred("input_pickable", false)
		modulate = Color("727272")

func _process(_delta):
	if selected:
		position = get_global_mouse_position() + offset
		handle_snap()

func pressed():
	start_position = global_position
	selected = true
	offset = global_position - get_global_mouse_position()
	button_glow.modulate = Color(Color.WHITE, 1.0)
	button_sprite.texture = held_texture

func released():
	selected = false
	if draggable.get_overlapping_areas().is_empty():
		global_position = start_position
	button_glow.modulate = Color(Color.WHITE, 0.5)
	button_sprite.texture = normal_texture

func sort_closest(a: Vector2, b: Vector2):
	var distance_to = func(point: Vector2):
		return global_position.distance_squared_to(point)
	return distance_to.call(a) < distance_to.call(b)

func handle_snap():
	if not has_overlapping_areas():
		return

	var line = get_overlapping_areas().front().get_parent()
	if not line is Line2D:
		return

	var points = Array(line.points)
	points = points.map(func(point): return point + line.global_position)
	points.sort_custom(sort_closest)
	var closest_point = points[0]
	
	var player: ScreenPlayer = line.get_parent()

	if (global_position + offset).distance_to(closest_point) < SNAP_BREAK_DISTANCE:
		global_position = closest_point
		player.update_new_action_line()
	else:
		player.clear_new_action_line()

func _on_mouse_entered() -> void:
	button_glow.show()

func _on_mouse_exited() -> void:
	button_glow.hide()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pressed()
		else:
			released()