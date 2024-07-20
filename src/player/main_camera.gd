extends Camera2D
class_name MainCamera

const CAMERA = {
	NORMAL_ZOOM = 0.5,
	FOLLOW_SPEED = 5.0,
	PEEK_DISTANCE = 1000.0, # Number of pixels that the camera will peek up (1920x1080 game)
	PEEK_TOWARD_SPEED = 2.0, # lerp speed, unitless
	MAP_EXIT_DISTANCE = 700.0,
	MAP_ZOOM = 1.5,
	MAP_ZOOM_SPEED = 3.0,
	MAP_TRANSLATE_SPEED = 6.0,
}

@export var player: Player

@onready var shake_timer: Timer = $ShakeTimer

var game: Game
var focus: Node2D = null
var shake_amount: float

func _ready():
	# Connect signals
	Global.camera_shake.connect(_shake)
	Global.stop_camera_shake.connect(_stop_shake)
	Global.set_camera_focus.connect(_set_focus)
	# Find game scene
	var current_scene = get_tree().get_current_scene()
	if current_scene is Game:
		game = current_scene

func _process(delta):
	handle_focus(delta)
	handle_follow_player(delta)
	handle_shake()
	handle_particle_tracking()

## Zoom and translate the camera to focus on a screen
func handle_focus(delta):
	var zoom_amount = CAMERA.NORMAL_ZOOM
	if focus:
		# Lerp position to target position
		global_position = lerp(global_position, focus.global_position, CAMERA.MAP_TRANSLATE_SPEED * delta)
		zoom_amount = CAMERA.MAP_ZOOM
	zoom = lerp(zoom, Vector2.ONE * zoom_amount, CAMERA.MAP_ZOOM_SPEED * delta)

	# Check if focus should be broken
	if abs(player.position.x - position.x) > CAMERA.MAP_EXIT_DISTANCE:
		Global.set_camera_focus.emit(null)

## Set camera position to follow palyer. Also handles peeking, moving the
## camera up when the player presses [w]
func handle_follow_player(_delta):
	if focus:
		return
	if (
		Input.is_action_pressed("up") and
		player.is_on_floor()
	):
		# Peek up
		position = player.position + Vector2.UP * CAMERA.PEEK_DISTANCE
		position_smoothing_speed = CAMERA.PEEK_TOWARD_SPEED
	else:
		position = player.position
		position_smoothing_speed = CAMERA.FOLLOW_SPEED

## Shake the camera for a given time by changing [offset]
func handle_shake():
	if shake_timer.is_stopped():
		offset = Vector2.ZERO
		return
	var shake_offset = Vector2(
		randf_range( - 1, 1),
		randf_range( - 1, 1)
	) * shake_amount
	offset = shake_offset

## Track all particles to the camera. Particles must be organized in the scene
## tree like so:
## 	> root level node
## 		> CanvasLayer
##			> GPUParticles2D
func handle_particle_tracking():
	if game == null:
		return
	
	for child in game.active_level.get_child(0).get_children():
		if child != CanvasLayer:
			continue
		for child2 in child.get_children():
			if child2 is GPUParticles2D:
				child2.global_position = position

## Receiver for the global [camera_shake] signal
func _shake(duration: float, amount: float):
	shake_timer.stop()
	shake_timer.start(duration)
	shake_amount = amount

## Receiver for the global [stop_camera_shake] signal
func _stop_shake():
	shake_timer.stop()

## Receiver for the global [set_camera_focus] signal
func _set_focus(_focus: Node2D):
	focus = _focus
