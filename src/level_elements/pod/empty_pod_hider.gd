extends Node2D

@onready var black: ColorRect = $ColorRect
@onready var collision_box: CollisionShape2D = $StaticBody2D/CollisionShape2D

func handle_empty():
	black.visible = !black.visible
	collision_box.disabled = !collision_box.disabled