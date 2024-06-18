extends Area2D
class_name ArtificialGravity

var enabled: bool = true

func _ready() -> void:
	add_to_group("AGs")

func enable():
	enabled = true
	queue_redraw()

func disable():
	enabled = false
	queue_redraw()

#func _draw() -> void:
	#var color = Color.GREEN if enabled else Color.RED
	#draw_circle(Vector2.ZERO, 4, color)
	#draw_arc(Vector2.ZERO, $CollisionShape2D.shape.radius, 0, TAU, 20, color, 2)
