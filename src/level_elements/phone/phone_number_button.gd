extends Area2D
class_name PhoneNumberButton

@export var number: int

signal clicked(button: PhoneNumberButton)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	):
		clicked.emit(self)
