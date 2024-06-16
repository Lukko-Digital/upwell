extends CharacterBody2D
class_name Player

const PLAYER = {
	SPEED = 150.0,
	ACCELERATION = 800.0,
	FRICTION_DECEL = 1500.0,
	JUMP_VELOCITY = -300.0
}
const ARTIFICIAL_GRAVITY = {
	SPEED = 350.0,
	ACCEL = 0.1,
}

@onready var gravity_detector: Area2D = $GravityDetector
@onready var interactable_detector: Area2D = $InteractableDetector
@onready var dialogue_ui: DialogueUI = $DialogueUi

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var interacting: bool = false

func _physics_process(delta):
	if interacting:
		return
	repel()
	attract()
	handle_gravity(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta / 1.5
 
func repel():
	var gravity_regions: Array[Area2D] = gravity_detector.get_overlapping_areas()
	if Input.is_action_pressed("repel") and not gravity_regions.is_empty():
		var vec_to_gravity = (gravity_regions[0].global_position - global_position).normalized()
		velocity = velocity.lerp( - vec_to_gravity * ARTIFICIAL_GRAVITY.SPEED, ARTIFICIAL_GRAVITY.ACCEL)

func attract():
	var gravity_regions: Array[Area2D] = gravity_detector.get_overlapping_areas()
	if Input.is_action_pressed("attract") and not gravity_regions.is_empty():
		var vec_to_gravity = (gravity_regions[0].global_position - global_position).normalized()
		velocity = velocity.lerp(vec_to_gravity * ARTIFICIAL_GRAVITY.SPEED, ARTIFICIAL_GRAVITY.ACCEL)

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
	interacting = true
	dialogue_ui.start_dialogue(nearby_interactables[0])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_pressed("interact"):
		interact()

func _on_dialogue_ui_dialogue_finished() -> void:
	interacting = false
