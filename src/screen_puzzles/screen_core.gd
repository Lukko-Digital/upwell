extends Area2D
class_name ScreenCore

@export var label: RichTextLabel
@export_multiline var text: String
@export var indicator: TextureRect
@export var glow: Sprite2D

@onready var unopened_sprite: Sprite2D = $Unopened
@onready var opened_sprite: Sprite2D = $Opened

## BBCode ready text
@onready var parsed_text: String = BBCodeParser.parse(text)

func visit() -> void:
	label.text = parsed_text
	indicator.texture = opened_sprite.texture
	unopened_sprite.hide()
	opened_sprite.show()
	glow.show()
	glow.global_position = indicator.global_position + indicator.size / 2
