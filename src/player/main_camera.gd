extends Camera2D

const CAMERA = {
	NORMAL_ZOOM = 0.5,
	FOLLOW_SPEED = 5.0,
	PEEK_DISTANCE = 1000.0, # Number of pixels that the camera will peek up (1920x1080 game)
	PEEK_TOWARD_SPEED = 2.0, # lerp speed, unitless
	# PEEK_RETURN_SPEED = 7.0, # lerp speed, unitless
	MAP_EXIT_DISTANCE = 700.0,
	MAP_ZOOM = 1.5,
	MAP_ZOOM_SPEED = 3.0,
	MAP_TRANSLATE_SPEED = 6.0,
}

@export var player: Player

var focus: Node2D = null

func _ready():
	Global.set_camera_focus.connect(_set_focus)

func _process(delta):
	if focus:
		global_position = lerp(global_position, focus.global_position, CAMERA.MAP_TRANSLATE_SPEED * delta)
		zoom = lerp(zoom, Vector2.ONE * CAMERA.MAP_ZOOM, CAMERA.MAP_ZOOM_SPEED * delta)
	else:
		zoom = lerp(zoom, Vector2.ONE * CAMERA.NORMAL_ZOOM, CAMERA.MAP_ZOOM_SPEED * delta)
		handle_camera_peek(delta)

	if player.position.x - position.x > CAMERA.MAP_EXIT_DISTANCE:
		Global.set_camera_focus.emit(null)

func handle_camera_peek(_delta):
	if Input.is_action_pressed("up") and player.is_on_floor():
		position = player.position + Vector2.UP * CAMERA.PEEK_DISTANCE
		position_smoothing_speed = CAMERA.PEEK_TOWARD_SPEED
		# lerp(
		# 	position,
		# 	player.position + Vector2.UP * CAMERA.PEEK_DISTANCE,
		# 	CAMERA.PEEK_TOWARD_SPEED * delta
		# )
	else:
		position = player.position
		position_smoothing_speed = CAMERA.FOLLOW_SPEED
		# lerp(
		# 	position,
		# 	player.position,
		# 	CAMERA.FOLLOW_SPEED * delta
		# )

func _set_focus(_focus: Node2D):
	focus = _focus
