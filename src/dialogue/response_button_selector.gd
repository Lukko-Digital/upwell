extends Sprite2D
class_name ResponseButtonSelector

const SPEED = 20.0 # lerp speed

@export var response_box: VBoxContainer

var focused_button: ResponseButton

func _ready() -> void:
	position.x = response_box.global_position.x + response_box.size.x * response_box.scale.x / 2
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)

func _process(delta: float) -> void:
	if not visible:
		return
	var target_y = get_center_y_position(focused_button)
	if position.y != target_y:
		position.y = lerp(position.y, target_y, SPEED * delta)

func get_center_y_position(button: ResponseButton):
	return button.global_position.y + button.size.y * response_box.scale.y / 2

func teleport_to_button(button: ResponseButton):
	position.y = get_center_y_position(button)

func _on_gui_focus_changed(node: Control):
	if node is ResponseButton:
		focused_button = node