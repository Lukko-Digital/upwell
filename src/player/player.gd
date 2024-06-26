extends GravitizedBody
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

@export var has_drill: bool = true:
	set(value):
		$DrillSprite.visible = value
		has_drill = value

@export_group("Node References")
@export var sprite: AnimatedSprite2D
@export var interactable_detector: Area2D
@export var drill_detector: Area2D
@export var wall_ray_cast: RayCast2D
@export var dialogue_ui: DialogueUI
@export var drill_input_held_timer: Timer
@export var interact_tap_timer: Timer
@export var throw_arc_line: Line2D

@onready var drill_scene: PackedScene = preload ("res://src/player/drill.tscn")
@onready var clicker_scene: PackedScene = preload ("res://src/level_elements/clicker/clicker.tscn")

var game: Game

## -------------------------- PLAYER STATE VARIABLES --------------------------

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var in_dialogue: bool = false
var in_map: bool = false
# ---

var has_clicker: bool:
	set(value):
		$NudgePosition/ClickerGlow.visible = value
		Global.player_has_clicker = value
		has_clicker = value

var was_moving: bool = false

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

### ------------------------------ CORE ------------------------------

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
	handle_world_gravity(delta, gravity_state, PLAYER.MAX_FALL_SPEED)
	var input_dir = handle_movement(delta, gravity_state)
	handle_animation(input_dir)
	move_and_slide()

func _process(_delta):
	handle_throw_arc()
	handle_nearby_interactables()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_released("jump"):
		jump_end()
	
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
	
	## The `drill_input_held_timer` is the time for which the drill key needs to
	## be held to insert or remove the drill from the wall. If the key is held
	## for the full duration the drill is inserted or removed from the wall.
	## If the key is released within the "tap time" it counts as tapping the key
	## and the drill is put down or picked up, or gotten into, based on the
	## state of the drill.
	if event.is_action_pressed("drill"):
		drill_input_held_timer.start(DRILL.INPUT_HOLD_TIME)
	if event.is_action_released("drill"):
		if DRILL.INPUT_HOLD_TIME - drill_input_held_timer.time_left < DRILL.INPUT_TAP_TIME:
			drill_interact()
		drill_input_held_timer.stop()

## ------------------------------ MOVEMENT ------------------------------

func calculate_speed_coef():
	speed_coef = 1
	if has_drill:
		speed_coef *= DRILL.SLOWDOWN

func handle_artificial_gravity(delta) -> GravityState:
	if not has_clicker:
		return GravityState.NONE
	return super(delta)

# Returns x input direction to be used by animation handler
func handle_movement(delta: float, gravity_state: GravityState) -> float:
	var top_speed = PLAYER.SPEED * speed_coef

	# friction
	if abs(velocity.x) > top_speed and is_on_floor():
		# if moving over top speed and on ground
		velocity.x = move_toward(velocity.x, 0, PLAYER.FRICTION_DECEL * delta)

	# nudge input
	if handle_nudge(gravity_state):
		return 0

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

func jump():
	if is_on_floor():
		velocity.y = -PLAYER.JUMP_VELOCITY * speed_coef

func jump_end():
	if velocity.y < 0:
		velocity.y -= PLAYER.JUMP_RELEASE_SLOWDOWN * velocity.y

### --- ANIMATION ---

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
	sprite.play("idle")
	dialogue_ui.start_dialogue(npc)
	in_dialogue = true

## ------------------------------ DRILL ------------------------------

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

## ------------------------------ SIGNAL HANDLES ------------------------------

func _on_dialogue_ui_dialogue_finished() -> void:
	in_dialogue = false

func _on_level_unlocked(_level_name: Global.LevelIDs):
	var ui = $Ui
	ui.show()
	await get_tree().create_timer(2).timeout
	ui.hide()
