extends Camera2D

var mouse_starting_position
var starting_position
var is_dragging = false

func _ready():
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			starting_position = position
			mouse_starting_position = event.position
			is_dragging = true
		else:
			is_dragging = false
	if event is InputEventMouseMotion and is_dragging:
		position = starting_position - zoom * (event.position - mouse_starting_position)