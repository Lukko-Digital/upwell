extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement()
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement():
	var direction = Input.get_axis("left", "right")
	velocity.x = direction * SPEED

func jump():
	velocity.y = JUMP_VELOCITY

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()