extends CharacterBody2D

const PLAYER = {
	SPEED = 150.0,
	ACCELERATION = 800.0,
	FRICTION_DECEL = 1500.0,
	JUMP_VELOCITY = -300.0
}
const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const DRILL = {
	LAUNCH_SPEED = 600.0,
	ATTRACT_FORCE = 1200.0
}

@onready var drill_scene = preload ("res://src/drill_bit.tscn")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var drill = null

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement(delta):
	# magnet attraction
	if drill and Input.is_action_pressed("attract"):
		velocity += (drill.global_position - global_position).normalized() * DRILL.ATTRACT_FORCE * delta

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
		velocity.y = JUMP_VELOCITY

func shoot():
	var instance: RigidBody2D = drill_scene.instantiate()
	instance.position = global_position
	instance.set_axis_velocity((get_global_mouse_position() - global_position).normalized() * DRILL.LAUNCH_SPEED)
	get_parent().add_child(instance)
	drill = instance

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	elif event.is_action_pressed("shoot"):
		shoot()
