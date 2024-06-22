extends CharacterBody2D
class_name Player

const PLAYER = {
	SPEED = 900.0,
	ACCELERATION = 7000.0, # move_toward acceleration, pixels/frame^2
	FRICTION_DECEL = 5000.0,
	JUMP_VELOCITY = 1800.0,
	JUMP_RELEASE_SLOWDOWN = 0.5,
	MAX_FALL_SPEED = 2600,
	WORLD_GRAVITY = 5000.0,
	DRILL_SLOWDOWN = 0.3,
	DRILL_INPUT_HOLD_TIME = 1.0,
	DRILL_INPUT_TAP_TIME = 0.5,
}

const ARTIFICIAL_GRAVITY = {
	SPEED = 3000.0,
	ACCELERATION = 4.0, # lerp acceleration, unitless
	BOOST_VELOCITY = 3000.0,
	NUDGE_DISTANCE = 50.0,
	NUDGE_ACCELERATION = 0.1, # lerp acceleration, unitless
}

@onready var sprite: AnimatedSprite2D = $NudgePosition/AnimatedSprite2D
@onready var gravity_detector: Area2D = $GravityDetector
@onready var interactable_detector: Area2D = $InteractableDetector
@onready var drill_detector: Area2D = $DrillDetector
@onready var dialogue_ui: DialogueUI = $DialogueUi
@onready var drill_input_held_timer: Timer = $DrillInputHeldTimer

@onready var drill_scene: PackedScene = preload ("res://src/player/drill.tscn")

var game: Game

## --- PLAYER STATE VARIABLES ---

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var in_dialogue: bool = false
var in_map: bool = false

var has_clicker: bool:
	set(value):
		$NudgePosition/Clicker.visible = value
		Global.player_has_clicker = value
		has_clicker = value

var has_drill: bool = true:
	set(value):
		$DrillSprite.visible = value
		has_drill = value

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
	var gravitized = handle_artificial_gravity(delta)
	handle_world_gravity(delta)
	var input_dir = handle_movement(delta, gravitized)
	handle_animation(input_dir)
	move_and_slide()

func calculate_speed_coef():
	speed_coef = 1
	if has_drill:
		speed_coef *= PLAYER.DRILL_SLOWDOWN
 
# Return true if attracting or repelling, false otherwise
func handle_artificial_gravity(delta) -> bool:
	if not has_clicker:
		return false

	var gravity_regions: Array[Area2D] = gravity_detector.get_overlapping_areas()
	if gravity_regions.is_empty():
		return false
	
	var gravity_well: ArtificialGravity = gravity_regions[0]
	if not gravity_well.enabled:
		return false
	
	var vec_to_gravity = gravity_well.global_position - global_position

	# Boost
	if Input.is_action_just_pressed("boost"):
		velocity = (-vec_to_gravity + nudge_position).normalized() * ARTIFICIAL_GRAVITY.BOOST_VELOCITY * speed_coef
		gravity_well.disable()

	# Push and pull
	if Input.is_action_pressed("attract"):
		velocity = velocity.lerp(
			vec_to_gravity.normalized() * ARTIFICIAL_GRAVITY.SPEED * speed_coef,
			ARTIFICIAL_GRAVITY.ACCELERATION * delta
		)
		return true
	if Input.is_action_pressed("repel"):
		velocity = velocity.lerp(
			( - vec_to_gravity + nudge_position).normalized() * ARTIFICIAL_GRAVITY.SPEED * speed_coef,
			ARTIFICIAL_GRAVITY.ACCELERATION * delta
		)
	
	return false

func handle_world_gravity(delta):
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, PLAYER.MAX_FALL_SPEED, PLAYER.WORLD_GRAVITY * delta)

# Returns x input direction to be used by animation handler
func handle_movement(delta: float, gravitized: bool) -> float:
	var top_speed = PLAYER.SPEED * speed_coef

	# friction
	if abs(velocity.x) > top_speed and is_on_floor():
		# if moving over top speed and on ground
		velocity.x = move_toward(velocity.x, 0, PLAYER.FRICTION_DECEL * delta)

	# nudge input
	if gravitized:
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
		instance.global_position = global_position
		get_parent().add_child(instance)
	else:
		# Check if drill is nearby and pickup
		var overlapping_areas = drill_detector.get_overlapping_areas()
		if overlapping_areas.is_empty():
			return
		var drill: Drill = overlapping_areas[0]
		drill.interact(self)

func drill_input_held():
	$DrillSprite.flip_v = !$DrillSprite.flip_v

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_released("jump"):
		jump_end()
	if event.is_action_pressed("interact"):
		interact()
	if event.is_action_pressed("map"):
		in_map = game.toggle_map()
	
	if event.is_action_pressed("drill"):
		drill_input_held_timer.start(PLAYER.DRILL_INPUT_HOLD_TIME)
	if event.is_action_released("drill"):
		if PLAYER.DRILL_INPUT_HOLD_TIME - drill_input_held_timer.time_left < PLAYER.DRILL_INPUT_TAP_TIME:
			drill_interact()
		drill_input_held_timer.stop()

func _on_dialogue_ui_dialogue_finished() -> void:
	in_dialogue = false

func _on_level_unlocked(_level_name: String):
	var ui = $Ui
	ui.show()
	await get_tree().create_timer(2).timeout
	ui.hide()