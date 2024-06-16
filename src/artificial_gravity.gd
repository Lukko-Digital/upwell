extends Area2D
class_name ArtificialGravity

func _draw() -> void:
    draw_arc(Vector2.ZERO, $CollisionShape2D.shape.radius, 0, TAU, 20, Color.GREEN, 2)