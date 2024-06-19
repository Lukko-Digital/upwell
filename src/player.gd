extends CharacterBody2D
class_name Player

const PLAYER = {
	SPEED = 900.0,
	ACCELERATION = 7000.0,
	FRICTION_DECEL = 5000.0,
	JUMP_VELOCITY = -2300.0,
	MAX_FALL_SPEED = 2600,
	WORLD_GRAVITY = 5000.0,
}

const ARTIFICIAL_GRAVITY = {
	SPEED = 380.0 * 8,
	ACCEL = 4.0,
	BOOST_VELOCITY = 3000.0,
	DEADZONE_SIZE = 0,
}

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
		has_clicker = value

func _ready() -> void:
	has_clicker = false
	var current_scene = get_tree().get_current_scene()
	if current_scene is Game:
		game = current_scene

func _physics_process(delta):
	if in_dialogue or in_map:
		return
	handle_artificial_gravity(delta)
	handle_world_gravity(delta)
	handle_movement(delta)
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
	
	var vec_to_gravity = gravity_well.global_position - global_position
	if vec_to_gravity.length() < ARTIFICIAL_GRAVITY.DEADZONE_SIZE:
		return
	
	var active_direction = Vector2.ZERO
	var attracting = Input.is_action_pressed("attract")
	var repelling = Input.is_action_pressed("repel")
	if not (attracting or repelling):
		return
	if attracting:
		active_direction += vec_to_gravity.normalized()
	if repelling:
		active_direction -= vec_to_gravity.normalized()
	
	velocity = velocity.lerp(active_direction * ARTIFICIAL_GRAVITY.SPEED, ARTIFICIAL_GRAVITY.ACCEL * delta)

	if Input.is_action_just_pressed("boost"):
		if active_direction == Vector2.ZERO:
			return
		velocity += active_direction * ARTIFICIAL_GRAVITY.BOOST_VELOCITY
		gravity_well.disable()

func handle_movement(delta):
	# friction
	if abs(velocity.x) > PLAYER.SPEED and is_on_floor():
		# if moving over top speed and on ground
		velocity.x = move_toward(velocity.x, 0, PLAYER.FRICTION_DECEL * delta)

	# directional input
	var direction = Input.get_axis("left", "right")
	if abs(velocity.x) < PLAYER.SPEED or sign(velocity.x) != sign(direction):
		# if moving under top speed or input is in direction opposite to movement
		velocity.x = move_toward(velocity.x, PLAYER.SPEED * direction, PLAYER.ACCELERATION * delta)

func jump():
	if is_on_floor():
		velocity.y = PLAYER.JUMP_VELOCITY

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
	if event.is_action_pressed("interact"):
		interact()
	if event.is_action_pressed("map"):
		game.map_layer.visible = !game.map_layer.visible
		in_map = game.map_layer.visible

func _on_dialogue_ui_dialogue_finished() -> void:
	in_dialogue = false
