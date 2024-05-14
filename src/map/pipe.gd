extends ColorRect

@onready var hovered_box = $Hovered

func _on_mouse_entered():
	hovered_box.show()

func _on_mouse_exited():
	hovered_box.hide()
