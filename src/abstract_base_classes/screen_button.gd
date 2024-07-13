extends Area2D
class_name ScreenButton

enum ButtonTypes {NONE, BOOST, UNORBIT, ORBIT}

@export var type = ButtonTypes.NONE

@onready var button_glow: Sprite2D = $ButtonGlow
@onready var draggable: Area2D = $ScreenDraggable

var selected: bool = false
var offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

func _ready():
	button_glow.hide()
	button_glow.modulate = Color(Color.WHITE, 0.5)
	draggable.input_event.connect(_on_area_2d_input_event)
	draggable.mouse_entered.connect(_on_mouse_entered)
	draggable.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	button_glow.show()

func _on_mouse_exited() -> void:
	button_glow.hide()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# LMB pressed
				start_position = global_position
				selected = true
				offset = global_position - get_global_mouse_position()
				button_glow.modulate = Color(Color.WHITE, 1.0)
			else:
				# LMB released
				selected = false
				if draggable.get_overlapping_areas().is_empty():
					global_position = start_position
				button_glow.modulate = Color(Color.WHITE, 0.5)
		
func _process(_delta):
	if selected:
		position = get_global_mouse_position() + offset
	