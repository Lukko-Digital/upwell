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
const LIMIT_DEFAULT = 10000000

@export var player: Player

# Node References
@onready var bound_up_ray: RayCast2D = %BoundUp
@onready var bound_down_ray: RayCast2D = %BoundDown
@onready var bound_left_ray: RayCast2D = %BoundLeft
@onready var bound_right_ray: RayCast2D = %BoundRight
@onready var track_up_ray: RayCast2D = %TrackUp
@onready var track_down_ray: RayCast2D = %TrackDown
@onready var shake_timer: Timer = $ShakeTimer

## Should be 3840 x 2160, double 1920 x 1080
@onready var viewport_size = get_viewport().get_visible_rect().size / CAMERA.NORMAL_ZOOM

var focus: Node2D = null
var shake_amount: float

func _ready():
	# Connect signals
	Global.camera_shake.connect(_shake)
	Global.stop_camera_shake.connect(_stop_shake)
	Global.set_camera_focus.connect(_set_focus)

func _process(delta):
	handle_focus(delta)
	handle_limits()
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

## Checks for train tracks, bounds and point focuses and sets limits accordingly.
func handle_limits():
	reset_limits()
	var tracked = handle_camera_track()
	handle_camera_bounds(tracked)

func reset_limits():
	limit_top = -LIMIT_DEFAULT
	limit_bottom = LIMIT_DEFAULT
	limit_left = -LIMIT_DEFAULT
	limit_right = LIMIT_DEFAULT

## Raycast for [CameraTrack], if found, set top and bottom limits.
## Returns true if a [CameraTrack] is found, otherwise false
func handle_camera_track() -> bool:
	for ray in [track_up_ray, track_down_ray]:
		var col_point = get_ray_collision(ray, CameraTrack)
		if col_point != null:
			limit_bottom = col_point.y + viewport_size.y / 2 + 2
			limit_top = col_point.y - viewport_size.y / 2 - 2
			return true
	return false

## Raycast for [CameraBound], if found, set limits. If the camera is on a track
## [tracked], only horizontal bounds will be set.
func handle_camera_bounds(tracked):
	# Set horizontal bounds
	var left_point = get_ray_collision(bound_left_ray, CameraBound)
	if left_point != null:
		limit_left = left_point.x

	var right_point = get_ray_collision(bound_right_ray, CameraBound)
	if right_point != null:
		limit_right = right_point.x

	# Don't set vertical bounds if tracked
	if tracked:
		return

	# Set vertical bounds
	var up_point = get_ray_collision(bound_up_ray, CameraBound)
	if up_point != null:
		limit_top = up_point.y

	var down_point = get_ray_collision(bound_down_ray, CameraBound)
	if down_point != null:
		limit_bottom = down_point.y

## Checks if the collider of [ray] is of type [type], if so, returns the
## collision point. Otherwise returns null.
func get_ray_collision(ray: RayCast2D, type: Variant):
	if is_instance_of(ray.get_collider(), type):
		return ray.get_collision_point()
	return null

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

## Track all particles to the camera
func handle_particle_tracking():
	get_tree().call_group("Particles", "move_particles", position)

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
