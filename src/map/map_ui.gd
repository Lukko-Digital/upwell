extends Control

signal change_camera_height(change)

func _input(event):
	if event.is_action_pressed("ui_up"):
		emit_signal("change_camera_height", 0.1)
	if event.is_action_pressed("ui_down"):
		emit_signal("change_camera_height", -0.1)
		