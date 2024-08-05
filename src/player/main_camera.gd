extends Camera2D
class_name MainCamera

const FOCUS_LERP_TRANSLATE_SPEED = 6.0
const ZOOM_LERP_SPEED = 3.0
const ZOOM_AMOUNT = {
	DEFAULT = 0.5,
	SCREEN = 1.5,
	NPC = 0.7,
	SPOT = 0.65,
	PHONE = 8
}
const SMOOTHING_SPEEDS = {
	FOLLOW = 5.0,
	PEEK = 2.0
}
const PEEK_DISTANCE = 1000.0 # Number of pixels that the camera will peek up
const SCREEN_FOCUS_BREAK_DISTANCE = 700.0

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
@onready var viewport_size = get_viewport().get_visible_rect().size / ZOOM_AMOUNT.DEFAULT

## LIFO stack, the last element in the array is focused
var focus_stack: Array[Node2D] = []

var shake_amount: float
var target_shake_amount: float
var shake_lerp_speed: float
var zoom_target: float = CAMERA.NORMAL_ZOOM
var zooming: bool = false
var current_zoom_tween: Tween
var zooming_to = CAMERA.NORMAL_ZOOM

func _ready():
	# Connect signals

	if get_tree().get_current_scene() is Game:
		# If playing game scene, only set the real main camera to global
		if get_parent() is Game:
			Global.main_camera = self
	else:
		# If not playing game scene, set self
		Global.main_camera = self

func _process(delta):
	handle_focus(delta)
	handle_zoom()
	handle_limits()
	handle_follow_player()
	handle_shake(delta)
	handle_particle_tracking()
	# print(zooming_to != zoom_target)
	# print(zoom, " | ", zoom_target)
	# print(zoom == Vector2.ONE * zoom_target)

## -------------------------- GETTING & SETTING FOCUS --------------------------

## If [focus_] is null stack is popped, otherwise the node is pushed to the
## end of the stack
func set_focus(focus_: Node2D):
	if focus_ == null:
		focus_stack.pop_back()
	else:
		focus_stack.append(focus_)
	Global.camera_focus_changed.emit(focus_)

## Returns the [Node2D] that is being focused or [null] if there is no focus
func current_focus() -> Node2D:
	return focus_stack.back()

## -------------------------- CAMERA MOVEMENT  --------------------------

## Translate the camera to focus on a focus point. Zoom on screens.
func handle_focus(delta):
	if focus_stack.is_empty():
		return

	# Lerp and zoom to screen position
	if current_focus() is ScreenInteractable:
		lerp_position(0.8, 1.0, 0, delta)
		zoom_target = ZOOM_AMOUNT.SCREEN
		# Check if focus should be broken
		if (abs(player.position.x - position.x) > SCREEN_FOCUS_BREAK_DISTANCE):
			set_focus(null)
	
	# Zoom position to between player and npc
	elif current_focus() is NPC:
		lerp_position(0.5, 0.5, get_viewport().get_visible_rect().size.y * 0.1, delta)
		zoom_target = ZOOM_AMOUNT.NPC
	
	# Zoom position to camera point focus
	elif current_focus() is Marker2D:
		lerp_position(0.6, 1.0, 0, delta)
		zoom_amount = CAMERA.SPOT_ZOOM

## Checks that zoom is equal to zoom_target, and if not, tweens zoom over ZOOM_DURATION to zoom_target
func handle_zoom():
	if zoom == Vector2.ONE * zoom_target:
		zooming = false
		return
	
	if zooming && zooming_to == zoom_target:
		return
	
	zooming = true
	zooming_to = zoom_target
	if current_zoom_tween:
		current_zoom_tween.kill()
	current_zoom_tween = create_tween()
	current_zoom_tween.tween_property(self, "zoom", Vector2.ONE * zooming_to, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Creates correct in between for player and focus with intensity between 0 and 1, 1 meaning target gets full control of camera in that dimension and 0 giving control to player
func lerp_position(x_intensity: float, y_intensity: float, y_offset: float, delta):
	var in_between = Vector2(
		current_focus().global_position.lerp(player.global_position, 1.0 - x_intensity).x,
		current_focus().global_position.lerp(player.global_position, 1.0 - y_intensity).y - y_offset
		)
	global_position = lerp(global_position, in_between, FOCUS_LERP_TRANSLATE_SPEED * delta)

## Checks for train tracks and bounds and sets limits accordingly. Prioritizes
## point focuses, then train tracks, then bounds.
func handle_limits():
	reset_limits()
	if not focus_stack.is_empty():
		return
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

## Set camera position to follow player, resets zoom to default. Also handles
## peeking, moving the camera up when the player presses [w].
func handle_follow_player():
	if not focus_stack.is_empty():
		return
	if (
		Input.is_action_pressed("up") and
		player.is_on_floor()
	):
		# Peek up
		position = player.position + Vector2.UP * PEEK_DISTANCE
		position_smoothing_speed = SMOOTHING_SPEEDS.PEEK
	else:
		position = player.position
		position_smoothing_speed = SMOOTHING_SPEEDS.FOLLOW
		
	zoom_target = ZOOM_AMOUNT.DEFAULT

## -------------------------- PARTICLES --------------------------

## Track all particles to the camera
func handle_particle_tracking():
	get_tree().call_group("Particles", "move_particles", position)

## -------------------------- SHAKE --------------------------

## Shake the camera for a given time by changing [offset]
func handle_shake(delta):
	shake_amount = lerp(shake_amount, target_shake_amount, delta * shake_lerp_speed)

	if shake_timer.is_stopped():
		offset = Vector2.ZERO
		return
	var shake_offset = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	) * shake_amount
	offset = shake_offset

func set_shake(duration: float, amount: float):
	shake_timer.stop()
	shake_timer.start(duration)
	shake_amount = amount

func set_shake_lerp(target_amount: float, lerp_speed: float):
	target_shake_amount = target_amount
	shake_lerp_speed = lerp_speed

func set_shake_and_lerp_to_zero(amount: float, lerp_speed: float):
	shake_amount = amount
	set_shake_lerp(0, lerp_speed)

func start_shake():
	shake_timer.start(INF)

func stop_shake():
	shake_timer.stop()
