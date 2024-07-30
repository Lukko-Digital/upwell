extends Area2D
class_name ScreenCore

@export_multiline var text: String
@export var folder_button: FolderButton

@onready var folder_sprite: AnimatedSprite2D = $FolderSprite
@onready var hover_glow: Sprite2D = $HoverGlow

## BBCode ready text
var parsed_text: String
## The folder is closed until opened by solving the puzzle
var opened = false:
	set(value):
		if value:
			folder_sprite.play("open")
			visit()
		else:
			folder_sprite.play("closed")
		opened = value

func _ready() -> void:
	parsed_text = BBCodeParser.parse(text)
	folder_button.parsed_text = parsed_text

func visit() -> void:
	folder_button.opened = true

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	):
		if not opened:
			return
		visit()

func _on_mouse_entered() -> void:
	if not opened:
		return
	hover_glow.show()

func _on_mouse_exited() -> void:
	hover_glow.hide()