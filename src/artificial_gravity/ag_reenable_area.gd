extends Area2D
class_name AGReenableArea

func _on_body_entered(body: Node2D) -> void:
	if body is Player or RigidBody2D:
		get_tree().call_group("AGs", "enable")
