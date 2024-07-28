extends TextureButton
class_name FolderButton

@onready var glow: Sprite2D = $FolderGlow

## Set by paried [ScreenCore]
var parsed_text: String

signal folder_opened(text: String)

func _ready() -> void:
	disabled = true

func _on_toggled(toggled_on: bool) -> void:
	glow.visible = toggled_on
	if toggled_on:
		folder_opened.emit(parsed_text)