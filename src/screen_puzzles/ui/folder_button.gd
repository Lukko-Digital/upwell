extends TextureRect
class_name FolderButton

@export var closed_texture: Texture2D
@export var open_texture: Texture2D

@onready var hover_glow: Sprite2D = $HoverGlow
@onready var selected_glow: Sprite2D = $SelectedGlow

## Set by paired [ScreenCore]
var parsed_text: String
## The folder is closed until opened by solving the puzzle
var opened = false:
	set(value):
		if value:
			texture = open_texture
			selected()
		else:
			texture = closed_texture
		opened = value

signal folder_opened(text: String)

func _ready() -> void:
	add_to_group("FolderButtons")

func selected():
	get_tree().call_group("FolderButtons", "deselect")
	selected_glow.show()
	folder_opened.emit(parsed_text)

func deselect():
	selected_glow.hide()

func _on_gui_input(event: InputEvent) -> void:
	# When LMB pressed
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	):
		if not opened:
			return
		selected()

func _on_mouse_entered() -> void:
	if not opened:
		return
	hover_glow.show()

func _on_mouse_exited() -> void:
	hover_glow.hide()