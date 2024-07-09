extends Area2D
class_name ClickerBlocker

const DEFAULT_WIDTH = 50
const DEFAULT_HEIGHT = 1060

@export var sprite: Sprite2D

func _ready() -> void:
	# Expects a capsule CollisionShape2D called "CollisionShape2D"
	sprite.scale.x = $CollisionShape2D.shape.radius / DEFAULT_WIDTH
	sprite.scale.y = $CollisionShape2D.shape.height / DEFAULT_HEIGHT