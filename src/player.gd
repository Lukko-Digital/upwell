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
	SPEED = 380.0 * 8,
	ACCEL = 4.0,
	BOOST_VELOCITY = 2500.0
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gravity_detector: Area2D = $GravityDetector
@onready var interactable_detector: Area2D = $InteractableDetector
@onready var dialogue_ui: DialogueUI = $DialogueUi

var game: Game

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var in_dialogue: bool = false
var in_map: bool = false

var has_clicker: bool:
	set(value):
		$Clicker.visible = value
		Global.player_has_clicker = value
		has_clicker = value

var was_moving: bool = false

func _ready() -> void:
	Global.level_unlocked.connect(_on_level_unlocked)
	has_clicker = Global.player_has_clicker
	var current_scene = get_tree().get_current_scene()
	if current_scene is Game:
		game = current_scene

func _physics_process(delta):
	if in_dialogue or in_map:
		return
	handle_artificial_gravity(delta)
	handle_world_gravity(delta)
	var input_dir = handle_movement(delta)
	handle_animation(input_dir)
	move_and_slide()

func handle_world_gravity(delta):
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, PLAYER.MAX_FALL_SPEED, PLAYER.WORLD_GRAVITY * delta)
 
func handle_artificial_gravity(delta):
	if not has_clicker:
		return

	var gravity_regions: Array[Area2D] = gravity_detector.get_overlapping_areas()
	if gravity_regions.is_empty():
		return
	
	var gravity_well: ArtificialGravity = gravity_regions[0]
	if not gravity_well.enabled:
		return
	
	var vec_to_gravity = (gravity_well.global_position - global_position).normalized()

	# Push and pull
	var active_direction = Vector2.ZERO
	if Input.is_action_pressed("attract"):
		active_direction += vec_to_gravity
	if Input.is_action_pressed("repel"):
		active_direction -= vec_to_gravity
	velocity = velocity.lerp(active_direction * ARTIFICIAL_GRAVITY.SPEED, ARTIFICIAL_GRAVITY.ACCEL * delta)
	
	# Boost
	if Input.is_action_just_pressed("boost"):
		velocity -= vec_to_gravity * ARTIFICIAL_GRAVITY.BOOST_VELOCITY
		gravity_well.disable()

func handle_movement(delta) -> float:
	# friction
	if abs(velocity.x) > PLAYER.SPEED and is_on_floor():
		# if moving over top speed and on ground
		velocity.x = move_toward(velocity.x, 0, PLAYER.FRICTION_DECEL * delta)

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
		return
	nearby_interactables[0].interact(self)

func start_dialogue(npc: NPC):
	dialogue_ui.start_dialogue(npc)
	in_dialogue = true

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
