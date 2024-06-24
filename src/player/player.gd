extends CharacterBody2D
class_name Player

const PLAYER = {
	# Walking / strafing
	SPEED = 900.0,
	ACCELERATION = 7000.0, # move_toward acceleration, pixels/frame^2
	FRICTION_DECEL = 5000.0,
	# Jumping
	JUMP_VELOCITY = 1800.0,
	JUMP_RELEASE_SLOWDOWN = 0.5,
	# Falling
	MAX_FALL_SPEED = 2600,
	# Throw
	THROW_VELOCITY = 3000,
	ARC_POINTS = 100,
	INTERACT_HOLD_TIME = 1.0,
	INTERACT_TAP_TIME = 0.5,
}
const DRILL = {
	SLOWDOWN = 0.3,
	INPUT_HOLD_TIME = 1.0,
	INPUT_TAP_TIME = 0.5,
	INSERT_WALL_DISTANCE = 250,
}

const ARTIFICIAL_GRAVITY = {
	PUSHPULL_SPEED = 3000.0,
	ACCELERATION = 4.0, # lerp acceleration, unitless
	ORBIT_SPEED = 1500.0,
	BOOST_VELOCITY = 3000.0,
	NUDGE_DISTANCE = 50.0,
	NUDGE_ACCELERATION = 0.1, # lerp acceleration, unitless
}

enum GravityState {NONE, PUSHPULL, ORBIT}

@onready var sprite: AnimatedSprite2D = $NudgePosition/AnimatedSprite2D
@onready var gravity_detector: Area2D = $DetectionAreas/GravityDetector
@onready var interactable_detector: Area2D = $DetectionAreas/InteractableDetector
@onready var drill_detector: Area2D = $DetectionAreas/DrillDetector
@onready var wall_ray_cast: RayCast2D = $DetectionAreas/WallRayCast
@onready var dialogue_ui: DialogueUI = $DialogueUi
@onready var drill_input_held_timer: Timer = $Timers/DrillInputHeldTimer
@onready var interact_tap_timer: Timer = $Timers/InteractTapTimer
@onready var throw_arc_line: Line2D = $ThrowArc

@onready var drill_scene: PackedScene = preload ("res://src/player/drill.tscn")
@onready var clicker_scene: PackedScene = preload ("res://src/level_elements/clicker2.tscn")

var game: Game

var world_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

## --- PLAYER STATE VARIABLES ---

@export var has_drill: bool = true:
	set(value):
		$DrillSprite.visible = value
		has_drill = value

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var in_dialogue: bool = false
var in_map: bool = false
# ---

var has_clicker: bool:
	set(value):
		$NudgePosition/Clicker.visible = value
		Global.player_has_clicker = value
		has_clicker = value

var was_moving: bool = false

## ---

var nudge_position: Vector2 = Vector2.ZERO:
	set(value):
		$NudgePosition.position = value
		nudge_position = value

var speed_coef: float = 1

func _ready() -> void:
	# Connect signal
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
	calculate_speed_coef()
	var gravity_state: GravityState = handle_artificial_gravity(delta)
	handle_world_gravity(delta, gravity_state)
	var input_dir = handle_movement(delta, gravity_state)
	handle_animation(input_dir)
	move_and_slide()

func _process(_delta):
	handle_throw_arc()
func calculate_speed_coef():
	speed_coef = 1
	if has_drill:
		speed_coef *= DRILL.SLOWDOWN
 
# Return true if attracting or repelling, false otherwise
func handle_artificial_gravity(delta) -> GravityState:
	# Check for clicker
	if not has_clicker:
		return GravityState.NONE

	# Check that player is in an AG
	var gravity_regions: Array[Area2D] = gravity_detector.get_overlapping_areas()
	if gravity_regions.is_empty():
		return GravityState.NONE
	
	# Check the AG is enabled
	var gravity_well: ArtificialGravity = gravity_regions[0]
	if not gravity_well.enabled:
		return GravityState.NONE
	
	var vec_to_gravity = gravity_well.global_position - global_position

	# Boost
	if Input.is_action_just_pressed("boost"):
		velocity = (-vec_to_gravity + nudge_position).normalized() * ARTIFICIAL_GRAVITY.BOOST_VELOCITY * speed_coef
		gravity_well.disable()
		return GravityState.NONE

	# Check the player is inputting a mouse click
	var attracting = Input.is_action_pressed("attract")
	var repelling = Input.is_action_pressed("repel")
	if not (attracting or repelling):
		return GravityState.NONE

	match gravity_well.type:
		ArtificialGravity.AGTypes.PUSHPULL:
			# Push and pull
			var active_direction = Vector2.ZERO
			if attracting:
				active_direction += vec_to_gravity.normalized()
			if repelling:
				active_direction += (-vec_to_gravity + nudge_position).normalized()
			velocity = velocity.lerp(
				active_direction * ARTIFICIAL_GRAVITY.PUSHPULL_SPEED * speed_coef,
				ARTIFICIAL_GRAVITY.ACCELERATION * delta
			)
			return GravityState.PUSHPULL

		ArtificialGravity.AGTypes.ORBIT:
			# Orbit
			var active_direction = Vector2.ZERO
			if attracting:
				# Right click, clockwise
				active_direction = vec_to_gravity.orthogonal().normalized()
			if repelling:
				# Left click, counterclockwise
				active_direction = -vec_to_gravity.orthogonal().normalized()
			velocity = active_direction * ARTIFICIAL_GRAVITY.ORBIT_SPEED * speed_coef
			return GravityState.ORBIT
	return GravityState.NONE

func handle_world_gravity(delta: float, gravity_state: GravityState):
	if gravity_state == GravityState.ORBIT:
		return
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, PLAYER.MAX_FALL_SPEED, world_gravity * delta)

# Returns x input direction to be used by animation handler
func handle_movement(delta: float, gravity_state: GravityState) -> float:
	var top_speed = PLAYER.SPEED * speed_coef

	# friction
	if abs(velocity.x) > top_speed and is_on_floor():
		# if moving over top speed and on ground
		velocity.x = move_toward(velocity.x, 0, PLAYER.FRICTION_DECEL * delta)

	# nudge input
	if gravity_state == GravityState.PUSHPULL:
		var nudge_input = Input.get_vector("left", "right", "up", "down")
		nudge_position = nudge_position.lerp(
			nudge_input * ARTIFICIAL_GRAVITY.NUDGE_DISTANCE,
			ARTIFICIAL_GRAVITY.NUDGE_ACCELERATION
		)
		return 0
	nudge_position = nudge_position.lerp(Vector2.ZERO, ARTIFICIAL_GRAVITY.NUDGE_ACCELERATION)

	# walking & air strafing
	var direction = Input.get_axis("left", "right")
	if abs(velocity.x) < top_speed or sign(velocity.x) != sign(direction):
		# if moving under top speed or input is in direction opposite to movement
		velocity.x = move_toward(
			velocity.x,
			top_speed * direction,
			PLAYER.ACCELERATION * speed_coef * delta
		)
	return direction

func handle_animation(direction: float):
	if direction == 0 or not is_on_floor():
		if was_moving:
			if not is_on_floor():
				sprite.flip_h = !sprite.flip_h
			sprite.play("stop")
		else:
			if sprite.is_playing():
				return
			sprite.play("idle")
		was_moving = false
	else:
		sprite.play("run")
		sprite.flip_h = (direction == - 1)
		was_moving = true

func jump():
	if is_on_floor():
		velocity.y = -PLAYER.JUMP_VELOCITY * speed_coef

func jump_end():
	if velocity.y < 0:
		velocity.y -= PLAYER.JUMP_RELEASE_SLOWDOWN * velocity.y

func interact():
	var nearby_interactables = interactable_detector.get_overlapping_areas()
	if nearby_interactables.is_empty():
		return
	nearby_interactables[0].interact(self)

func throw():
	var dir = (get_global_mouse_position() - global_position).normalized()
	var instance: RigidBody2D = clicker_scene.instantiate()
	instance.global_position = global_position
	instance.set_axis_velocity(dir * PLAYER.THROW_VELOCITY)
	get_parent().add_child(instance)

func handle_throw_arc():
	if not (Input.is_action_pressed("interact") and interact_tap_timer.is_stopped()):
		throw_arc_line.clear_points()
		return
	throw_arc_line.clear_points()
	var pos = Vector2.ZERO
	var dir = (get_global_mouse_position() - global_position).normalized()
	# The throw is slightly slower than the projected arc, so we multiply the arc velocity by a factor of 0.97
	var vel = dir * PLAYER.THROW_VELOCITY * 0.97
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
	sprite.play("idle")
	dialogue_ui.start_dialogue(npc)
	in_dialogue = true

# On drill input tapped
func drill_interact():
	if has_drill:
		# Put down drill
		has_drill = false
		var instance: Drill = drill_scene.instantiate()
		instance.in_wall = false
		instance.global_position = global_position
		get_parent().add_child(instance)
	else:
		# Check if drill is nearby and pickup
		var overlapping_areas = drill_detector.get_overlapping_areas()
		if overlapping_areas.is_empty():
			return
		var drill: Drill = overlapping_areas[0]
		drill.interact(self)

# Take drill in and out of wall
func drill_input_held():
	if has_drill:
		# Check if wall
		var dir = -1 if sprite.flip_h else 1 # false = right, true = left
		wall_ray_cast.target_position.x = dir * DRILL.INSERT_WALL_DISTANCE
		wall_ray_cast.force_raycast_update()
		if not wall_ray_cast.is_colliding():
			return
		# Insert into wall
		has_drill = false
		var instance: Drill = drill_scene.instantiate()
		instance.in_wall = true
		instance.global_position = wall_ray_cast.get_collision_point()
		instance.rotation_degrees = dir * 90
		get_parent().add_child(instance)
	else:
		# Check if drill is nearby and pickup
		var overlapping_areas = drill_detector.get_overlapping_areas()
		if overlapping_areas.is_empty():
			return
		var drill: Drill = overlapping_areas[0]
		drill.remove_from_wall(self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_released("jump"):
		jump_end()
	
	if event.is_action_pressed("interact"):
		interact_tap_timer.start(PLAYER.INTERACT_TAP_TIME)
	if event.is_action_released("interact"):
		if !interact_tap_timer.is_stopped():
			interact()
			interact_tap_timer.stop()
		else:
			throw()
	
	if event.is_action_pressed("drill"):
		drill_input_held_timer.start(DRILL.INPUT_HOLD_TIME)
	if event.is_action_released("drill"):
		if DRILL.INPUT_HOLD_TIME - drill_input_held_timer.time_left < DRILL.INPUT_TAP_TIME:
			drill_interact()
		drill_input_held_timer.stop()

func _on_dialogue_ui_dialogue_finished() -> void:
	in_dialogue = false

func _on_level_unlocked(_level_name: String):
	var ui = $Ui
	ui.show()
	await get_tree().create_timer(2).timeout
	ui.hide()