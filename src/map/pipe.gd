extends ColorRect
class_name Pipe

@onready var hovered_box = $Hovered
@onready var hitbox = $Hitbox
@onready var info_tag = $InfoTag

@onready var pipe_info = $InfoTag/PipeInfo
@onready var too_far = $InfoTag/TooFar

signal clicked(pipe)

var player_can_move = false

func _ready():
	hide()
	info_tag.hide()

func _on_mouse_entered():
	hovered_box.show()
	info_tag.show()

func _on_mouse_exited():
	hovered_box.hide()
	info_tag.hide()

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
			too_far.hide()
		"VisionRadius":
			show()

func _on_hitbox_area_exited(area):
	match area.name:
		"MovementRadius":
			player_can_move = false
			too_far.show()
		"VisionRadius":
			hide()
