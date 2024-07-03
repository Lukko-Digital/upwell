extends GravitizedBody
class_name Player

const PLAYER = {
	# Walking / strafing
	SPEED = 900.0,
	ACCELERATION = 7000.0, # move_toward acceleration, pixels/frame^2
	FRICTION_DECEL = 5000.0,
	ORBIT_STRAFE_SLOWDOWN = 0.5, # percentage of standard speed
	PUSHPULL_STRAFE_SLOWDOWN = 0.5, # percentage of standard speed
	# Camera
	PEEK_DISTANCE = 1000.0, # Number of pixels that the camera will peek up (1920x1080 game)
	PEEK_TOWARD_SPEED = 5.0, # lerp speed, unitless
	PEEK_RETURN_SPEED = 7.0, # lerp speed, unitless
	# Jumping
	JUMP_VELOCITY = 2100.0,
	JUMP_RELEASE_SLOWDOWN = 0.5,
	MIN_JUMP_TIME = 0.1,
	COYOTE_TIME = 0.1, # Time you get to jump after running off a ledge
	JUMP_BUFFER_TIME = 0.3, # Time between a jump input and touching the ground that the jump will still go off
	# Falling
	MAX_FALL_SPEED = 2600,
	# Throw
	THROW_VELOCITY = 3000,
	ARC_POINTS = 100,
	INTERACT_TAP_TIME = 0.5,
}

@export_group("Settings")
@export var only_peek_on_ground: bool = false

@export_group("Node References")
@export var camera: Camera2D
@export var clicker_sprite: Sprite2D
@export var interactable_detector: Area2D
@export var dialogue_ui: DialogueUI
@export var interact_tap_timer: Timer
@export var coyote_timer: Timer
@export var jump_buffer_timer: Timer
@export var min_jump_timer: Timer
@export var throw_arc_line: Line2D

@onready var clicker_scene: PackedScene = preload ("res://src/clicker/clicker.tscn")

var game: Game

## -------------------------- PLAYER STATE VARIABLES --------------------------

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var in_dialogue: bool = false
var in_map: bool = false
# ---

var has_clicker: bool:
	set(value):
		clicker_sprite.visible = value
		Global.player_has_clicker = value
		has_clicker = value

var previously_grounded: bool = false
var jumping: bool = false
var disable_airborne_decel: bool = true
var previous_horizontal_direction: float = 0

## ---

var highlighted_interactable: Interactable = null:
	set(interactable):
		if interactable == highlighted_interactable:
			return
		if highlighted_interactable != null:
			highlighted_interactable.highlighted = false
		highlighted_interactable = interactable
		if highlighted_interactable != null:
			highlighted_interactable.highlighted = true

var default_camera_position: Vector2

### ------------------------------ CORE ------------------------------

func _ready() -> void:
	default_camera_position = camera.position
	# Connect signal
	min_jump_timer.timeout.connect(_min_jump_timer_timeout)
	Global.level_unlocked.connect(_on_level_unlocked)
	# Load clicker state
	has_clicker = Global.player_has_clicker
	# Retrieve Game node 
	var current_scene = get_tree().get_current_scene()
	if current_scene is Game:
		game = current_scene

func _physics_process(delta):
	if in_dialogue or in_map:
		return
	var gravity_state: GravityState = handle_artificial_gravity(delta)
	handle_world_gravity(delta, gravity_state, PLAYER.MAX_FALL_SPEED)
	handle_movement(delta, gravity_state)
	move_and_slide()
	handle_coyote_timing(gravity_state)

func _process(delta):
	handle_throw_arc()
	handle_nearby_interactables()
	handle_camera_peek(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_released("jump"):
		jump_end()
	if event.is_action_pressed("map"):
		in_map = game.toggle_map()
	
	## The `interact_tap_timer` is the time in which the interact key can be
	## released in order to count as tapping interact. If the key is held
	## beyond that time, it begins the throw action, via `handle_throw_arc`
	if event.is_action_pressed("interact"):
		interact_tap_timer.start(PLAYER.INTERACT_TAP_TIME)
	if event.is_action_released("interact"):
		if !interact_tap_timer.is_stopped():
			interact()
			interact_tap_timer.stop()
		else:
			throw()

## ------------------------------ CAMERA ------------------------------

func handle_camera_peek(delta):
	var can_peek = true
	if only_peek_on_ground and not is_on_floor():
		can_peek = false
	if Input.is_action_pressed("up") and can_peek:
		camera.position.y = lerp(
			camera.position.y,
			default_camera_position.y - PLAYER.PEEK_DISTANCE,
			PLAYER.PEEK_TOWARD_SPEED * delta
		)
	else:
		camera.position.y = lerp(
			camera.position.y,
			default_camera_position.y,
			PLAYER.PEEK_RETURN_SPEED * delta
		)

## ------------------------------ MOVEMENT ------------------------------

func handle_artificial_gravity(delta) -> GravityState:
	if not has_clicker:
		return GravityState.NONE
	return super(delta)

func handle_movement(delta: float, gravity_state: GravityState):
	var speed_coef = 1.0
	if gravity_state == GravityState.ORBIT:
		speed_coef = PLAYER.ORBIT_STRAFE_SLOWDOWN
	elif gravity_state == GravityState.PUSHPULL:
		speed_coef = PLAYER.PUSHPULL_STRAFE_SLOWDOWN

	var top_speed = PLAYER.SPEED * speed_coef
	var horizontal_direction = sign(velocity.x)

	# friction when above top speed
	if abs(velocity.x) > top_speed and is_on_floor():
		# if moving over top speed and on ground
		velocity.x = move_toward(velocity.x, 0, PLAYER.FRICTION_DECEL * delta)

	# nudge input
	if handle_nudge(gravity_state):
		return

	# Disable airborne decel upon boosting until touching the floor or
	# changing direction in air.
	if gravity_state == GravityState.BOOST:
		disable_airborne_decel = true
	elif is_on_floor() or horizontal_direction != previous_horizontal_direction:
		disable_airborne_decel = false
	previous_horizontal_direction = horizontal_direction
	# walking & air strafing
	var input_direction = Input.get_axis("left", "right")
	if abs(velocity.x) < top_speed or horizontal_direction != sign(input_direction):
		# If moving under top speed or input is not in the same direction of
		# movement, accelerate player towards direction of movement, this
		# includes accelerating towards zero movement.
		if input_direction == 0 and (
			disable_airborne_decel or gravity_state in [GravityState.ORBIT, GravityState.PUSHPULL]
		):
			# If there is no player input, and airborne decel is disabled from
			# boosting or the player is currently in an orbit or pushpull,
			# exit so the player is not decelerated.
			return
		velocity.x = move_toward(
			velocity.x,
			top_speed * input_direction,
			PLAYER.ACCELERATION * speed_coef * delta
		)

# ----------------------------- JUMP -----------------------------

## Should be called after [move_and_slide] in [_physics_process]
func handle_coyote_timing(gravity_state: GravityState):
	var currently_grounded = is_on_floor()
	if (
		previously_grounded and
		not currently_grounded and
		not jumping and
		gravity_state == GravityState.NONE
	):
		coyote_timer.start(PLAYER.COYOTE_TIME)

	if currently_grounded or gravity_state != GravityState.NONE:
		jumping = false
	if not jump_buffer_timer.is_stopped() and currently_grounded:
		jump()

	previously_grounded = currently_grounded
func jump():
	if is_on_floor() or not coyote_timer.is_stopped():
		velocity.y = -PLAYER.JUMP_VELOCITY
		jumping = true
		coyote_timer.stop()
		min_jump_timer.start(PLAYER.MIN_JUMP_TIME)
	else:
		jump_buffer_timer.start(PLAYER.JUMP_BUFFER_TIME)

func jump_end():
	if (
		velocity.y < 0 and
		min_jump_timer.is_stopped() and
		jumping
	):
		velocity.y -= PLAYER.JUMP_RELEASE_SLOWDOWN * velocity.y

func _min_jump_timer_timeout():
	if !Input.is_action_pressed("jump"):
		jump_end()

### ----------------------------- OBJECT INTERACT -----------------------------

func handle_nearby_interactables():
	var nearby_interactables = interactable_detector.get_overlapping_areas().filter(
		func(interactable): return interactable.interact_condition(self)
	)
	if nearby_interactables.is_empty():
		highlighted_interactable = null
	else:
		var distance_to = func(node):
			return interactable_detector.global_position.distance_squared_to(node.global_position)
		nearby_interactables.sort_custom(
			func(a, b): return distance_to.call(a) < distance_to.call(b)
		)
		highlighted_interactable = nearby_interactables[0]

func spawn_clicker(initial_velocity: Vector2=Vector2.ZERO):
	has_clicker = false
	var instance: ClickerBody = clicker_scene.instantiate()
	instance.global_position = global_position
	instance.velocity = initial_velocity
	get_parent().add_child(instance)

func interact():
	if highlighted_interactable != null:
		highlighted_interactable.interact(self)
	elif has_clicker:
		spawn_clicker()

func throw():
	if not has_clicker:
		return
	var dir = (get_global_mouse_position() - global_position).normalized()
	spawn_clicker(dir * PLAYER.THROW_VELOCITY)

func handle_throw_arc():
	if not (
		Input.is_action_pressed("interact") and
		interact_tap_timer.is_stopped() and
		has_clicker
	):
		throw_arc_line.clear_points()
		return
	throw_arc_line.clear_points()
	var pos = Vector2.ZERO
	var vel = (get_global_mouse_position() - global_position).normalized() * PLAYER.THROW_VELOCITY
	var delta = get_physics_process_delta_time()
	var world_physics := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_bodies = true
	query.collision_mask = 1
	for i in PLAYER.ARC_POINTS:
		throw_arc_line.add_point(pos)
		vel.y += world_gravity * delta
		pos += vel * delta
		query.position = global_position + pos
		if not world_physics.intersect_point(query).is_empty():
			break

func start_dialogue(npc: NPC):
	if in_dialogue:
		return
	dialogue_ui.start_dialogue(npc)
	in_dialogue = true

## ------------------------------ SIGNAL HANDLES ------------------------------

func _on_dialogue_ui_dialogue_finished() -> void:
	in_dialogue = false

func _on_level_unlocked(_level_name: Global.LevelIDs):
	var ui = $Ui
	ui.show()
	await get_tree().create_timer(2).timeout
	ui.hide()
