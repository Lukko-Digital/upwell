extends Area2D
class_name ScreenCore

@export_multiline var text: String
@export var folder_button: FolderButton

@onready var unopened_sprite: Sprite2D = $Unopened
@onready var opened_sprite: Sprite2D = $Opened

## BBCode ready text
var parsed_text: String

func _ready() -> void:
	parsed_text = BBCodeParser.parse(text)
	folder_button.parsed_text = parsed_text

func visit() -> void:
	unopened_sprite.hide()
	opened_sprite.show()
	folder_button.opened = true