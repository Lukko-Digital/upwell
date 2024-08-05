extends TextureRect

@onready var glow_sprite: Sprite2D = $LightGlowDodge

func _ready() -> void:
	glow_sprite.material = glow_sprite.material.duplicate()
	glow()

func glow():
	glow_sprite.show()

func unglow():
	glow_sprite.hide()