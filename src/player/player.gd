extends CharacterBody2D
class_name Player

const PLAYER = {
	SPEED = 900.0,
	ACCELERATION = 7000.0,
	FRICTION_DECEL = 5000.0,
	JUMP_VELOCITY = 1800.0,
	JUMP_RELEASE_SLOWDOWN = 0.5,
	MAX_FALL_SPEED = 2600,
	WORLD_GRAVITY = 5000.0,
}

const ARTIFICIAL_GRAVITY = {
	SPEED = 3000.0,
	ACCEL = 4.0,
	BOOST_VELOCITY = 3000.0,
	NUDGE_DISTANCE = 50.0,
}

@onready var sprite: AnimatedSprite2D = $NudgePosition/AnimatedSprite2D
@onready var gravity_detector: Area2D = $GravityDetector
@onready var interactable_detector: Area2D = $InteractableDetector
@onready var dialogue_ui: DialogueUI = $DialogueUi

@onready var drill_scene: PackedScene = preload ("res://src/player/drill.tscn")

var game: Game

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

var nudge_position: Vector2 = Vector2.ZERO:
	set(value):
		$NudgePosition.position = value
		nudge_position = value

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
	var gravitized = handle_artificial_gravity(delta)
	handle_world_gravity(delta)
	var input_dir = handle_movement(delta, gravitized)
	handle_animation(input_dir)
	move_and_slide()

func handle_world_gravity(delta):
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, PLAYER.MAX_FALL_SPEED, PLAYER.WORLD_GRAVITY * delta)
 
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
		velocity = (-vec_to_gravity + nudge_position).normalized() * ARTIFICIAL_GRAVITY.BOOST_VELOCITY
		gravity_well.disable()

	# Push and pull
	if Input.is_action_pressed("attract"):
		velocity = velocity.lerp(
			vec_to_gravity.normalized() * ARTIFICIAL_GRAVITY.SPEED,
			ARTIFICIAL_GRAVITY.ACCEL * delta
		)
		return true
	if Input.is_action_pressed("repel"):
		velocity = velocity.lerp(
			( - vec_to_gravity + nudge_position).normalized() * ARTIFICIAL_GRAVITY.SPEED,
			ARTIFICIAL_GRAVITY.ACCEL * delta
		)
	
	return false

func handle_movement(delta: float, gravitized: bool) -> float:
	# friction
	if abs(velocity.x) > PLAYER.SPEED and is_on_floor():
		# if moving over top speed and on ground
		velocity.x = move_toward(velocity.x, 0, PLAYER.FRICTION_DECEL * delta)

	# nudge input
	if gravitized:
		var nudge_input = Input.get_vector("left", "right", "up", "down")
		nudge_position = nudge_position.lerp(nudge_input * ARTIFICIAL_GRAVITY.NUDGE_DISTANCE, 0.1)
		return 0
	nudge_position = nudge_position.lerp(Vector2.ZERO, 0.1)

	# directional input
	var direction = Input.get_axis("left", "right")
	if abs(velocity.x) < PLAYER.SPEED or sign(velocity.x) != sign(direction):
		# if moving under top speed or input is in direction opposite to movement
		velocity.x = move_toward(velocity.x, PLAYER.SPEED * direction, PLAYER.ACCELERATION * delta)
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
		velocity.y = -PLAYER.JUMP_VELOCITY

func jump_end():
	if velocity.y < 0:
		velocity.y -= PLAYER.JUMP_RELEASE_SLOWDOWN * velocity.y

func interact():
	var nearby_interactables = interactable_detector.get_overlapping_areas()
	if nearby_interactables.is_empty():
		if has_drill:
			put_down_drill()
		return
	nearby_interactables[0].interact(self)

func start_dialogue(npc: NPC):
	if in_dialogue:
		return
	sprite.play("idle")
	dialogue_ui.start_dialogue(npc)
	in_dialogue = true

func put_down_drill():
	has_drill = false
	var instance: Drill = drill_scene.instantiate()
	instance.global_position = global_position
	get_parent().add_child(instance)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_released("jump"):
		jump_end()
	if event.is_action_pressed("interact"):
		interact()
	if event.is_action_pressed("map"):
		in_map = game.toggle_map()

func _on_dialogue_ui_dialogue_finished() -> void:
	in_dialogue = false

func _on_level_unlocked(_level_name: String):
	var ui = $Ui
	ui.show()
	await get_tree().create_timer(2).timeout
	ui.hide()
