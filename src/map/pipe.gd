extends ColorRect
class_name Pipe

@onready var hovered_box = $Hovered
@onready var hitbox = $Hitbox

signal clicked(pipe)

var player_can_see = false
var player_can_move = false

func _on_mouse_entered():
	hovered_box.show()

func _on_mouse_exited():
	hovered_box.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT and
			event.pressed and
			player_can_move
		):
			clicked.emit(self)

func _on_hitbox_area_entered(area):
	match area.name:
		"MovementRadius":
			player_can_move = true
		"VisionRadius":
			player_can_see = true

func _on_hitbox_area_exited(area):
	match area.name:
		"MovementRadius":
			player_can_move = false
		"VisionRadius":
			player_can_see = false
