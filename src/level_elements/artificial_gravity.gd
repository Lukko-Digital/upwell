extends Area2D
class_name Interactable

func _draw() -> void:
    draw_circle(Vector2.ZERO, 4, Color.GREEN)
    draw_arc(Vector2.ZERO, $CollisionShape2D.shape.radius, 0, TAU, 20, Color.GREEN, 2)