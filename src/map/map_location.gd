extends Area2D
class_name MapLocation

@onready var player: MapPlayer = get_tree().get_current_scene().get_node("MapPlayer")

# func _ready() -> void:
# 	print(get_tree().get_current_scene())
# 	print(get_parent())

func _on_mouse_entered() -> void:
	player.location_hovered(self)

func _on_mouse_exited() -> void:
	player.location_unhovered(self)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			player.location_selected(self)
