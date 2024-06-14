extends CharacterBody3D

const PLAYER = {
	SPEED = 5.0,
	JUMP_VELOCITY = 12.0
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta * 2

func handle_movement(_delta):
	var direction = Input.get_axis("left", "right")
	velocity.x = direction * PLAYER.SPEED

func jump():
	if is_on_floor():
		velocity.y = PLAYER.JUMP_VELOCITY

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()