extends CharacterBody2D
class_name Player

const PLAYER = {
	# Walking / strafing
	SPEED = 900.0,
	ACCELERATION = 7000.0, # move_toward acceleration, pixels/frame^2
	ORBIT_STRAFE_SLOWDOWN = 0.5, # percentage of standard speed
	PUSHPULL_STRAFE_SLOWDOWN = 0.5, # percentage of standard speed
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
}

@export_group("Node References")
@export var camera: Camera2D
@export var grav_component: GravitizedComponent
@export var interactable_detector: Area2D
@export var dialogue_ui: DialogueUI
@export var level_unlock_popup: CanvasLayer
@export var coyote_timer: Timer
@export var jump_buffer_timer: Timer
@export var min_jump_timer: Timer
@export var throw_arc_line: Line2D

@onready var clicker_scene: PackedScene = preload ("res://src/clicker/clicker.tscn")

## Emitted when player gains or loses a clicker
signal clicker_count_changed

var world_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var game: Game

var clicker_inventory: Array[ClickerInfo]

## -------------------------- PLAYER STATE VARIABLES --------------------------

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var in_dialogue: bool = false

# Jumping + Air Strafing
var previously_grounded: bool = false
var jumping: bool = false
var disable_airborne_decel: bool = true
var previous_horizontal_direction: float = 0

# Throwing
var aiming: bool = false
var focused_on_screen: bool = false

var highlighted_interactable: Interactable = null:
	set(interactable):
		if interactable == highlighted_interactable:
			return
		if highlighted_interactable != null:
			highlighted_interactable.highlighted = false
		highlighted_interactable = interactable
		if highlighted_interactable != null:
			highlighted_interactable.highlighted = true

### ------------------------------ CORE ------------------------------

func _ready() -> void:
	# Connect signal
	min_jump_timer.timeout.connect(_min_jump_timer_timeout)
	Global.set_camera_focus.connect(_camera_focus_net)

	# Retrieve Game node 
	var current_scene = get_tree().get_current_scene()
	if current_scene is Game and not owner is Game:
		# var main_camera: Camera2D = current_scene.get_node("Camera2D")
		# main_camera.limit_bottom = camera.limit_bottom
		# main_camera.limit_top = camera.limit_top
		camera.queue_free()
		queue_free()

func _physics_process(delta):
	if in_dialogue:
		return
	var gravity_state: GravitizedComponent.GravityState = handle_artificial_gravity(delta)
	handle_world_gravity(delta, gravity_state)
	handle_movement(delta, gravity_state)
	move_and_slide()
	handle_coyote_timing(gravity_state)

func _process(_delta):
	handle_throw_arc()
	handle_nearby_interactables()
	handle_controllable_clickers()

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
		aiming = true
	if event.is_action_pressed("cancel"):
		aiming = false
	
	if event.is_action_released("throw"):
		throw()

## ------------------------------ GRAVITY ------------------------------

func handle_artificial_gravity(delta) -> GravitizedComponent.GravityState:
	if not has_clicker():
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

func handle_movement(delta: float, gravity_state: GravitizedComponent.GravityState):
	var speed_coef = 1.0
	if gravity_state == GravitizedComponent.GravityState.ORBIT:
		speed_coef = PLAYER.ORBIT_STRAFE_SLOWDOWN
	elif gravity_state == GravitizedComponent.GravityState.PUSHPULL:
		speed_coef = PLAYER.PUSHPULL_STRAFE_SLOWDOWN

	var top_speed = PLAYER.SPEED * speed_coef
	var horizontal_direction = sign(velocity.x)
	
	# Disable airborne decel upon boosting until touching the floor or
	# changing direction in air.
	if gravity_state == GravitizedComponent.GravityState.BOOST:
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
			disable_airborne_decel or gravity_state in [
				GravitizedComponent.GravityState.ORBIT, GravitizedComponent.GravityState.PUSHPULL
			]
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
	# No jump when holding shift
	if Input.is_action_pressed("orbit"):
		return
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

func sort_closest(a: Node2D, b: Node2D):
	var distance_to = func(node: Node2D):
		return global_position.distance_squared_to(node.global_position)
	return distance_to.call(a) < distance_to.call(b)

func handle_nearby_interactables():
	var nearby_interactables = interactable_detector.get_overlapping_areas().filter(
		func(interactable): return interactable.interact_condition(self)
	)
	if nearby_interactables.is_empty():
		highlighted_interactable = null
	else:
		nearby_interactables.sort_custom(sort_closest)
		highlighted_interactable = nearby_interactables[0]

func interact():
	if highlighted_interactable != null:
		highlighted_interactable.interact(self)
	elif has_clicker():
		spawn_clicker()

func start_dialogue(npc: NPC):
	if in_dialogue:
		return
	dialogue_ui.start_dialogue(npc)
	in_dialogue = true

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
	var clicker_info = ClickerInfo.new(clicker.home_holder)
	clicker_inventory.append(clicker_info)
	clicker_count_changed.emit()
	clicker.queue_free()

func spawn_clicker(
	initial_velocity: Vector2=Vector2.ZERO
) -> ClickerBody:
	if not has_clicker():
		return
	var clicker_info: ClickerInfo = clicker_inventory.pop_front()
	clicker_count_changed.emit()
	var instance = clicker_scene.instantiate()
	instance.home_holder = clicker_info.home_holder
	instance.linear_velocity = initial_velocity
	get_parent().add_child.call_deferred(instance)
	instance.set_deferred("global_position", global_position)
	return instance

func home_all_clickers():
	while has_clicker():
		var clicker = spawn_clicker()
		clicker.return_to_home()

### ----------------------------- THROW -----------------------------

func throw():
	if not (
		has_clicker() and
		aiming and
		not focused_on_screen and
		not in_dialogue
	):
		return
	var dir = (get_global_mouse_position() - global_position).normalized()
	spawn_clicker(dir * PLAYER.THROW_VELOCITY)

func handle_throw_arc():
	throw_arc_line.clear_points()

	if not (
		Input.is_action_pressed("throw") and
		has_clicker() and
		aiming and
		not focused_on_screen and
		not in_dialogue
	):
		return

	var pos = Vector2.ZERO
	## The rigid body flies in a parabola with slightly less amplitude than
	## the one calculated below. We add the adjustment factor so the line
	## better matches the actual curve of the throw. Unsure why this is the
	## case. The line fit when using a character body clicker with coded in
	## physics.
	var adjustment_factor = 0.97
	var vel = (get_global_mouse_position() - global_position).normalized() * PLAYER.THROW_VELOCITY * adjustment_factor
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

## ------------------------------ SIGNAL HANDLES ------------------------------

func _on_dialogue_ui_dialogue_finished() -> void:
	in_dialogue = false

func _camera_focus_net(focus: Node2D):
	if focus == null:
		focused_on_screen = false
	else:
		focused_on_screen = true