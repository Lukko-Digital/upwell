extends Camera2D

@onready var player: MapPlayer = get_parent()
## This relies on the [ScreenInteractable] for map in pod.tscn being named "Screen"
@onready var screen: ScreenInteractable = find_parent("Screen")

const ZOOM_LOWER_BOUND = 0.1
const ZOOM_UPPER_BOUND = 0.2

var panning: bool = false
var mouse_start: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var player_destination: Entrypoint = null

func _ready() -> void:
	player.select_destination.connect(destination_selected)
	assert(
		screen != null,
		"Couldn't find parent named 'Screen'. Expected the map screen in `pod.tscn` to be named 'Screen'."
	)

func _process(_delta: float) -> void:
	if player.moving:
		global_position = lerp(global_position, player.global_position, 0.01)
	elif player_destination:
		global_position = lerp(global_position, (player_destination.global_position + player.global_position) / 2, 0.01)

func handle_zoom(event: InputEvent):
	if not (
		screen.focused and
		event is InputEventMouseButton and
		event.is_pressed()
	):
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom *= 1.1
		player.location_deselected()
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom /= 1.1
		player.location_deselected()

	zoom = zoom.clamp(
		Vector2.ONE * ZOOM_LOWER_BOUND,
		Vector2.ONE * ZOOM_UPPER_BOUND
	)
	
func handle_pan(event: InputEvent):
	if not screen.focused:
		return
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT
	):
		if event.is_pressed() and not panning:
			# LMB pressed
			player.location_deselected()
			panning = true
			player_destination = null
		elif not event.is_pressed():
			# LMB released
			panning = false

	if event is InputEventMouseMotion and panning:
		global_position -= event.relative * 4

func _unhandled_input(event: InputEvent) -> void:
	handle_zoom(event)
	handle_pan(event)

func destination_selected(location: Entrypoint) -> void:
	player_destination = location
