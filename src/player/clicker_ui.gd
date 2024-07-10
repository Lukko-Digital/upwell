extends CanvasLayer
class_name ClickerUI

@export var player: Player
@export var clickers_sprite: AnimatedSprite2D

func _process(_delta: float) -> void:
	match player.clicker_inventory.size():
		0:
			clickers_sprite.hide()
		1:
			clickers_sprite.show()
			clickers_sprite.play("1")
		2:
			clickers_sprite.play("2")
		3:
			clickers_sprite.play("3")
