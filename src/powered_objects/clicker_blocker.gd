extends Area2D
class_name ClickerBlocker

const DEFAULT_WIDTH = 50
const DEFAULT_HEIGHT = 1060

@export var sprite: Sprite2D

func _ready() -> void:
	# Expects a capsule CollisionShape2D called "CollisionShape2D"
	sprite.scale.x = $CollisionShape2D.shape.radius / DEFAULT_WIDTH
	sprite.scale.y = $CollisionShape2D.shape.height / DEFAULT_HEIGHT

func enable():
	set_deferred("monitoring", true)
	sprite.frame = 0

func disable():
	set_deferred("monitoring", false)
	sprite.frame = 1

func _on_body_entered(body: Node2D) -> void:
	if body is ClickerBody:
		body.return_to_home()
	elif body is Player:
		body.home_all_clickers()