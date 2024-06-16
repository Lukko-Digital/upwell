extends CharacterBody2D
class_name Player

const PLAYER = {
	SPEED = 150.0,
	ACCELERATION = 800.0,
	FRICTION_DECEL = 1500.0,
	JUMP_VELOCITY = -300.0
}
const DRILL = {
	LAUNCH_SPEED = 1000.0,
	ATTRACT_SPEED = 400.0,
	REPEL_SPEED = 400.0,
	RECALL_SPEED = 8.0,
	ACCEL = 0.1,
	RECALL_BOOST = 400
}

@onready var pickup_area: Area2D = $PickupArea
@onready var interactable_detector: Area2D = $InteractableDetector
@onready var dialogue_ui: DialogueUI = $DialogueUi

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# PLACEHOLDER IMPLEMENTATION, TO BE IMPROVED
var interacting: bool = false

func _ready() -> void:
	dialogue_ui.hide()

func _physics_process(delta):
	if interacting:
		return
	var repelling = repel()
	var attracting = attract()
	handle_gravity(delta, attracting, repelling)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta, attracting, repelling):
	if attracting or repelling:
		return
	if not is_on_floor():
		velocity.y += gravity * delta / 1.5
 
func repel() -> bool:
	if Input.is_action_pressed("repel") and not pickup_area.get_overlapping_areas().is_empty() and not recalling:
		var vec_to_drill = (drill.global_position - global_position).normalized()
		velocity = velocity.lerp( - vec_to_drill * DRILL.ATTRACT_SPEED, DRILL.ACCEL)
		return true
	return false

func attract() -> bool:
	if not drill:
		return false
	if Input.is_action_pressed("attract") and not pickup_area.get_overlapping_areas().is_empty() and not recalling:
		var vec_to_drill = (drill.global_position - global_position).normalized()
		velocity = velocity.lerp(vec_to_drill * DRILL.ATTRACT_SPEED, DRILL.ACCEL)
		return true
	return false

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
