extends Node2D
class_name Pod

signal map_focused

func _on_sub_viewport_container_focus_entered():
	map_focused.emit()