extends CharacterBody2D
class_name Player

const PLAYER = {
	# Walking / strafing
	SPEED = 900.0,
	ACCELERATION = 7000.0, # move_toward acceleration, pixels/frame^2
	ORBIT_STRAFE_SLOWDOWN = 0.5, # percentage of standard speed
	# Jumping
	JUMP_VELOCITY = 2100.0,
	JUMP_RELEASE_SLOWDOWN = 0.5,
	MIN_JUMP_TIME = 0.1,
	COYOTE_TIME = 0.1, # Time you get to jump after running off a ledge
	JUMP_BUFFER_TIME = 0.3, # Time between a jump input and touching the ground that the jump will still go off
	# Falling
	MAX_FALL_SPEED = 2600
}

const THROW = {
	VELOCITY = 3000,
	ARC_POINTS = 100,
	## Equivalent to sensitivity, larger number is lower sensitivity
	CIRCLE_RADIUS = 150
}

const NPC_WALK_AWAY_DISTANCE = 200

var STARTING_THROW_DIRECTION = Vector2.UP

@export_group("Node References")
## Camera reference for a level's test player, does not need to be set for the
## player in [Game]
@export var camera: Camera2D
@export var player_sprite: AnimatedSprite2D
@export var grav_component: GravitizedComponent
@export var interactable_detector: Area2D
@export var dialogue_stand_detector: Area2D
@export var dialogue_ui: DialogueUI
@export var level_unlock_popup: CanvasLayer
@export var coyote_timer: Timer
@export var jump_buffer_timer: Timer
@export var min_jump_timer: Timer
@export var throw_arc_line: Line2D

@onready var clicker_scene: PackedScene = preload ("res://src/clicker/clicker.tscn")

## Emitted when player gains or loses a clicker
signal clicker_count_changed(increased: bool)

var world_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var game: Game

var clicker_inventory: Array[ClickerInfo]

## -------------------------- PLAYER STATE VARIABLES --------------------------

var focused_on_screen: bool = false

# Jumping + Air Strafing
var previously_grounded: bool = false
var jumping: bool = false
var disable_airborne_decel: bool = true
var previous_horizontal_direction: float = 0

# Throwing
var aiming: bool = false
## Is always a unit vector
var aiming_direction: Vector2

# Dialogue
var current_dialogue_npc: NPC = null
## Used for having the character initially move into place and face the NPC
## before entering dialogue.
var dialogue_start_location: DialogueStandLocation = null
## Used for having the charcter walk to set locations during scripted scenes
var scripted_dialogue_location: DialogueStandLocation = null

var highlighted_interactable: Interactable = null:
	set(interactable):
		if interactable == highlighted_interactable:
			return
		if highlighted_interactable != null:
			highlighted_interactable.highlighted = false
		highlighted_interactable = interactable
		if highlighted_interactable != null:
			highlighted_interactable.highlighted = true

## ------------------------------ CORE ------------------------------

func _ready() -> void:
	# Connect signal
	min_jump_timer.timeout.connect(_min_jump_timer_timeout)
	player_sprite.animation_finished.connect(_on_animation_finished)
	Global.set_camera_focus.connect(_camera_focus_net)

	# Retrieve Game node 
	var current_scene = get_tree().get_current_scene()
	# Kill level's test player
	if current_scene is Game and not owner is Game:
		camera.queue_free()
		queue_free()
	else:
		# Don't allow test players to set mouse mode
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	var gravity_state: GravitizedComponent.GravityState = handle_artificial_gravity(delta)
	handle_world_gravity(delta, gravity_state)
	var input_dir = handle_movement(delta, gravity_state)
	move_and_slide()
	handle_player_animation(input_dir, gravity_state)
	handle_coyote_timing(gravity_state)

func _process(_delta):
	handle_throw_arc()
	handle_nearby_interactables()
	handle_controllable_clickers()
	Global.dialogue_conditions["HAS_CLICKER"] = has_clicker()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_released("jump"):
		jump_end()
	
	## The `interact_tap_timer` is the time in which the interact key can be
	## released in order to count as tapping interact. If the key is held
	## beyond that time, it begins the throw action, via `handle_throw_arc`

	if event.is_action_pressed("interact"):
		interact()
	
	if event.is_action_pressed("throw"):
		if can_throw():
			aiming = true
			aiming_direction = STARTING_THROW_DIRECTION
			# if player_sprite.flip_h:
			# 	aiming_direction.x *= - 1
	if event.is_action_pressed("cancel"):
		if aiming:
			aiming = false
	if event is InputEventMouseMotion and aiming:
		handle_aiming_direction(event)

	if event.is_action_released("throw"):
		throw()

	if event.is_action_pressed("ui_cancel"):
		leave_dialogue()

## ------------------------------ GRAVITY ------------------------------

func handle_artificial_gravity(delta) -> GravitizedComponent.GravityState:
	if (
		not has_clicker() or
		in_dialogue()
	):
		return GravitizedComponent.GravityState.NONE

	var active_ag = grav_component.check_active_ag()
	var gravity_state = grav_component.determine_gravity_state(active_ag)
	if gravity_state != GravitizedComponent.GravityState.NONE:
		var new_vel = grav_component.calculate_gravitized_velocity(
			active_ag, gravity_state, velocity, delta
		)
		velocity = new_vel
	return gravity_state

func handle_world_gravity(delta: float, gravity_state: GravitizedComponent.GravityState):
	if gravity_state == GravitizedComponent.GravityState.ORBIT:
		return
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, PLAYER.MAX_FALL_SPEED, world_gravity * delta)

## ------------------------------ MOVEMENT ------------------------------

func handle_movement(delta: float, gravity_state: GravitizedComponent.GravityState) -> float:
	var speed_coef = 1.0
	if gravity_state == GravitizedComponent.GravityState.ORBIT:
		speed_coef = PLAYER.ORBIT_STRAFE_SLOWDOWN

	var top_speed = PLAYER.SPEED * speed_coef
	var horizontal_direction = sign(velocity.x)
	
	# Disable airborne decel upon boosting until touching the floor or
	# changing direction in air.
	if gravity_state == GravitizedComponent.GravityState.BOOST:
		disable_airborne_decel = true
	elif is_on_floor() or horizontal_direction != previous_horizontal_direction:
		disable_airborne_decel = false
	previous_horizontal_direction = horizontal_direction

	# Walking & air strafing
	var input_direction: float

	# If in dialogue, auto determine input_direction
	if in_dialogue():
		input_direction = handle_dialogue_movement()
	else:
		input_direction = Input.get_axis("left", "right")

	if abs(velocity.x) < top_speed or horizontal_direction != sign(input_direction):
		# If moving under top speed or input is not in the same direction of
		# movement, accelerate player towards direction of movement, this
		# includes accelerating towards zero movement.
		if input_direction == 0 and (
			disable_airborne_decel or gravity_state == GravitizedComponent.GravityState.ORBIT
		):
			# If there is no player input, and airborne decel is disabled from
			# boosting or the player is currently in an orbit, exit so the
			# player is not decelerated.
			return 0
		velocity.x = move_toward(
			velocity.x,
			top_speed * input_direction,
			PLAYER.ACCELERATION * speed_coef * delta
		)
	return input_direction

## Returns automatically determined input direction for player to move in
func handle_dialogue_movement() -> float:
	## If the conversation has been started, only consider scripted locations
	if dialogue_ui.current_npc == current_dialogue_npc:
		return walk_to_scripted_location()
	## Walk to start location and start the conversation
	else:
		return walk_to_dialogue_start()

## Used for having the character initially move into place and face the NPC
## before entering dialogue.
func walk_to_dialogue_start() -> float:
	# If midair, also stay still
	if not is_on_floor():
		return 0

	# If at location or if no location exists, start dialogue
	if dialogue_stand_detector.has_overlapping_areas() or dialogue_start_location == null:
		var dir_to_npc = sign(current_dialogue_npc.global_position.x - global_position.x)
		dialogue_start_location = null
		current_dialogue_npc.face_player(self)
		dialogue_ui.start_dialogue(current_dialogue_npc, dir_to_npc)
		# If facing the wrong way, turn to face npc
		var npc_to_the_right: bool = (dir_to_npc == 1)
		if player_sprite.flip_h == npc_to_the_right:
			return dir_to_npc
		else:
			return 0
	# Otherwise walk to location
	else:
		return sign(dialogue_start_location.global_position.x - global_position.x)

## Used for having the charcter walk to set locations during scripted scenes
func walk_to_scripted_location() -> float:
	if dialogue_stand_detector.has_overlapping_areas():
		# Location reached
		scripted_dialogue_location = null
	if scripted_dialogue_location == null:
		return 0
	return sign(scripted_dialogue_location.global_position.x - global_position.x)

## ----------------------------- ANIMATION -----------------------------

## Should be called after [move_and_slide] in [_physics_process], but before
## [handle_coyote_timing]
func handle_player_animation(input_dir: float, gravity_state: GravitizedComponent.GravityState):
	# Don't interrupt certain animations
	if (
		currently_playing("Jump")
	):
		return
	
	var dir_int = int(round(input_dir))

	# Handle flip direction
	match dir_int:
		- 1:
			player_sprite.flip_h = true
		1:
			player_sprite.flip_h = false
	
	if is_on_floor():
		# Grounded animation

		# Interrupt land animation past frame 1 when moving
		if dir_int != 0 and currently_playing("Land") and player_sprite.frame > 1:
			player_sprite.play("Run")
		elif not previously_grounded or currently_playing("Land"):
			player_sprite.play("Land")
		elif dir_int != 0:
			player_sprite.play("Run")
		elif dir_int == 0 and currently_playing("Run"):
			player_sprite.play("Stop")
		elif not currently_playing("Stop"):
			player_sprite.play("Idle")

	else:
		# Airborne animation
		if gravity_state == GravitizedComponent.GravityState.ORBIT:
			player_sprite.play("Hover")
		elif velocity.y > 0:
			# Falling
			if not currently_playing("Fall_Loop"):
				player_sprite.play("Fall_Start")

func _on_animation_finished():
	match player_sprite.animation:
		"Fall_Start":
			player_sprite.play("Fall_Loop")

func currently_playing(animation: String):
	return player_sprite.is_playing() and player_sprite.animation == animation

## ----------------------------- JUMP -----------------------------

## Should be called after [move_and_slide] in [_physics_process]
func handle_coyote_timing(gravity_state: GravitizedComponent.GravityState):
	var currently_grounded = is_on_floor()
	if (
		previously_grounded and
		not currently_grounded and
		not jumping and
		gravity_state == GravitizedComponent.GravityState.NONE
	):
		coyote_timer.start(PLAYER.COYOTE_TIME)

	if currently_grounded or gravity_state != GravitizedComponent.GravityState.NONE:
		jumping = false
	if not jump_buffer_timer.is_stopped() and currently_grounded:
		jump()

	previously_grounded = currently_grounded

func jump():
	# No jump when holding shift or when in dialogue
	if Input.is_action_pressed("orbit") or in_dialogue():
		return
	if is_on_floor() or not coyote_timer.is_stopped():
		velocity.y = -PLAYER.JUMP_VELOCITY
		jumping = true
		coyote_timer.stop()
		min_jump_timer.start(PLAYER.MIN_JUMP_TIME)
		player_sprite.play("Jump")
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

## ----------------------------- OBJECT INTERACT -----------------------------

func sort_closest(a: Node2D, b: Node2D):
	var distance_to = func(node: Node2D):
		return global_position.distance_squared_to(node.global_position)
	return distance_to.call(a) < distance_to.call(b)

func sort_closest_prioritize_clickers(a: Node2D, b: Node2D):
	var a_is_clicker = a is ClickerInteractable
	var b_is_clicker = b is ClickerInteractable
	if a_is_clicker != b_is_clicker:
		return a_is_clicker
	else:
		return sort_closest(a, b)

func handle_nearby_interactables():
	var nearby_interactables = interactable_detector.get_overlapping_areas().filter(
		func(interactable): return interactable.interact_condition(self)
	)
	if nearby_interactables.is_empty():
		highlighted_interactable = null
	else:
		nearby_interactables.sort_custom(sort_closest_prioritize_clickers)
		highlighted_interactable = nearby_interactables[0]

func interact():
	if in_dialogue():
		return

	if highlighted_interactable != null:
		highlighted_interactable.interact(self)
	elif has_clicker():
		spawn_clicker()

### ----------------------------- DIALOGUE -----------------------------

func in_dialogue():
	return current_dialogue_npc != null

## Called when player interacts with an NPC
func init_npc_interaction(npc: NPC):
	current_dialogue_npc = npc
	var standing_locations = npc.standing_locations.duplicate()
	if standing_locations.is_empty():
		return
	# Find closest standing location
	dialogue_start_location = standing_locations.pop_front()
	for loc: DialogueStandLocation in standing_locations:
		if abs(loc.global_position.x - global_position.x) < abs(dialogue_start_location.global_position.x - global_position.x):
			dialogue_start_location = loc

## Attempt to leave dialogue early by pressing [esc]
func leave_dialogue():
	if in_dialogue() and not dialogue_ui.locked_in_dialogue:
		dialogue_ui.exit_dialogue()

### ----------------------------- CLICKER -----------------------------

func has_clicker():
	return !clicker_inventory.is_empty()

func handle_controllable_clickers():
	get_tree().call_group("Clickers", "set_controllable", false)
	if not has_clicker():
		return
	var clickers = get_tree().get_nodes_in_group("Clickers")
	clickers.sort_custom(sort_closest)
	for _i in range(clicker_inventory.size()):
		if clickers.is_empty():
			break
		clickers.pop_front().set_controllable(true)
	
func add_clicker(clicker: ClickerBody):
	var clicker_info = ClickerInfo.new(clicker.home_holder, clicker.get_parent())
	clicker_inventory.append(clicker_info)
	clicker_count_changed.emit(true)
	clicker.queue_free()

func spawn_clicker(
	initial_velocity: Vector2=Vector2.ZERO
) -> ClickerBody:
	if not has_clicker():
		return
	var clicker_info: ClickerInfo = clicker_inventory.pop_front()
	clicker_count_changed.emit(false)
	var instance = clicker_scene.instantiate()
	instance.home_holder = clicker_info.home_holder
	instance.linear_velocity = initial_velocity
	clicker_info.parent_node.add_child.call_deferred(instance)
	instance.set_deferred("global_position", global_position)
	return instance

func home_all_clickers():
	while has_clicker():
		var clicker = spawn_clicker()
		clicker.return_to_home()

## ----------------------------- THROW -----------------------------

func can_throw():
	return (
		has_clicker() and
		not focused_on_screen and
		not in_dialogue()
	)

func throw():
	if not (
		can_throw() and
		aiming
	):
		return
	spawn_clicker(aiming_direction * THROW.VELOCITY)

func handle_aiming_direction(event: InputEventMouseMotion):
	aiming_direction = (aiming_direction * THROW.CIRCLE_RADIUS + event.relative).normalized()

func handle_throw_arc():
	throw_arc_line.clear_points()

	if not (
		Input.is_action_pressed("throw") and
		can_throw() and
		aiming
	):
		return

	var pos = Vector2.ZERO
	## The rigid body flies in a parabola with slightly less amplitude than
	## the one calculated below. We add the adjustment factor so the line
	## better matches the actual curve of the throw. Unsure why this is the
	## case. The line fit when using a character body clicker with coded in
	## physics.
	var adjustment_factor = 0.97
	var vel = aiming_direction * THROW.VELOCITY * adjustment_factor
	var delta = get_physics_process_delta_time()
	var world_physics := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_bodies = true
	query.collision_mask = 1
	for i in THROW.ARC_POINTS:
		throw_arc_line.add_point(pos)
		vel.y += world_gravity * delta
		pos += vel * delta
		query.position = global_position + pos
		if not world_physics.intersect_point(query).is_empty():
			break

## ------------------------------ SIGNAL HANDLES ------------------------------

func _on_dialogue_ui_dialogue_finished() -> void:
	current_dialogue_npc = null
	Global.set_camera_focus.emit(null)

func _camera_focus_net(focus: Node2D):
	# Simple implementation, does not factor in focus stack. Will be an issue
	# if play focuses on a screen and then on something else without defocusing
	# the screen, but that is unlikely to happen.
	if focus == null:
		focused_on_screen = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif focus is ScreenInteractable:
		focused_on_screen = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
