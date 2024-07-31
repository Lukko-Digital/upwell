extends Camera2D

@onready var player: MapPlayer = get_parent()

const ZOOM_LOWER_BOUND = 0.1
const ZOOM_UPPER_BOUND = 0.2

var panning: bool = false
var mouse_start: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var player_destination: Entrypoint = null

func _ready() -> void:
	player.select_destination.connect(destination_selected)

func _process(_delta: float) -> void:
	if player.moving:
		global_position = lerp(global_position, player.global_position, 0.01)
	elif player_destination:
		global_position = lerp(global_position, (player_destination.global_position + player.global_position) / 2, 0.01)
	# else:

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			zoom *= 1.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			zoom /= 1.1

		if zoom.x < ZOOM_LOWER_BOUND:
			zoom = Vector2.ONE * ZOOM_LOWER_BOUND
		if zoom.x > ZOOM_UPPER_BOUND:
			zoom = Vector2.ONE * ZOOM_UPPER_BOUND

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and not panning:
				# LMB pressed
				panning = true
				player_destination = null
			elif not event.is_pressed():
				# LMB released
				panning = false

	if event is InputEventMouseMotion and panning:
		global_position -= event.relative * 4

func destination_selected(location: Entrypoint) -> void:
	player_destination = location