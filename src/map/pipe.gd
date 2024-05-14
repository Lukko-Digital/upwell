extends ColorRect
class_name Pipe

@onready var hovered_box = $Hovered

signal clicked(pipe)

func _on_mouse_entered():
	hovered_box.show()

func _on_mouse_exited():
	hovered_box.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(self)
