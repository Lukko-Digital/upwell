extends Area2D
class_name ScreenCore

@export var label: Label
@export var indicator: TextureRect

@onready var unopened_sprite: Sprite2D = $Unopened
@onready var opened_sprite: Sprite2D = $Opened

func visit() -> void:
	label.show()
	indicator.texture = opened_sprite.texture
	unopened_sprite.hide()
	opened_sprite.show()