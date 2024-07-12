extends Area2D
class_name ScreenButton

enum ButtonTypes {NONE, BOOST, UNORBIT, ORBIT}

@export var type = ButtonTypes.NONE
@onready var draggable: Area2D = $ScreenDraggable

var selected: bool = false
var offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready():
	draggable.connect("input_event", _on_area_2d_input_event)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_position = global_position
			selected = true
			offset = global_position - get_global_mouse_position()
		else:
			selected = false
			if draggable.get_overlapping_areas().is_empty():
				global_position = start_position
		
func _process(_delta):
	if selected:
		position = get_global_mouse_position() + offset
	