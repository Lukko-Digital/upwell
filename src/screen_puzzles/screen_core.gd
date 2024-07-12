extends Area2D
class_name ScreenCore

@export var label: RichTextLabel
@export_multiline var text: String
@export var indicator: TextureRect
@export var glow: Sprite2D

@onready var unopened_sprite: Sprite2D = $Unopened
@onready var opened_sprite: Sprite2D = $Opened

func visit() -> void:
	label.text = text
	indicator.texture = opened_sprite.texture
	unopened_sprite.hide()
	opened_sprite.show()
	glow.show()
	glow.global_position = indicator.global_position + indicator.size / 2
