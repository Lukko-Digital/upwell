extends Camera2D

const ZOOM_LOWER_BOUND = 0.1
const ZOOM_UPPER_BOUND = 0.2

@onready var player: MapPlayer = get_parent()

func _process(_delta: float) -> void:
	if player.moving:
		lerp(global_position, player.global_position, 0.1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 1.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= 1.1

		if zoom.x < ZOOM_LOWER_BOUND:
			zoom = Vector2.ONE * ZOOM_LOWER_BOUND
		if zoom.x > ZOOM_UPPER_BOUND:
			zoom = Vector2.ONE * ZOOM_UPPER_BOUND
