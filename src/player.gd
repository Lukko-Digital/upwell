extends CharacterBody2D
class_name Player

const PLAYER = {
	SPEED = 150.0,
	ACCELERATION = 800.0,
	FRICTION_DECEL = 1500.0,
	JUMP_VELOCITY = -300.0
}
const DRILL = {
	LAUNCH_SPEED = 600.0,
	ATTRACT_FORCE = 1400.0,
	INITIAL_ATTRACT_SPEED = 300.0,
	REPEL_FORCE = 1400.0
}

@onready var drill_scene = preload ("res://src/drill_bit.tscn")
@onready var pickup_area: Area2D = $PickupArea

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var drill: RigidBody2D = null

func _physics_process(delta):
	handle_gravity(delta)
	handle_repel(delta)
	handle_attract(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_repel(delta):
	if not drill:
		if Input.is_action_just_pressed("repel"):
			shoot()
	else:
		var vec_to_drill = drill.global_position - global_position
		if Input.is_action_pressed("repel"):
			velocity += - vec_to_drill.normalized() * delta * clamp(DRILL.REPEL_FORCE * 100 / vec_to_drill.length(), 0, 2000)

func shoot():
	var instance: RigidBody2D = drill_scene.instantiate()
	instance.position = global_position
	instance.apply_central_impulse((get_global_mouse_position() - global_position).normalized() * DRILL.LAUNCH_SPEED)
	get_parent().add_child(instance)
	drill = instance

func handle_attract(delta):
	if not drill:
		return

	var vec_to_drill = (drill.global_position - global_position).normalized()
	if Input.is_action_pressed("down"):
		# recall drill
		if Input.is_action_pressed("attract"):
			drill.set_axis_velocity( - vec_to_drill * DRILL.ATTRACT_FORCE / 4)
			# drill.apply_central_force( - vec_to_drill * DRILL.ATTRACT_FORCE * 4)
	else:
		# attraction movement
		if Input.is_action_just_pressed("attract"):
			velocity += vec_to_drill * DRILL.INITIAL_ATTRACT_SPEED
		if Input.is_action_pressed("attract"):
			velocity += vec_to_drill * DRILL.ATTRACT_FORCE * delta
	if drill in pickup_area.get_overlapping_bodies() and Input.is_action_pressed("attract"):
		# "reattach" drill bit to player
		drill.queue_free()
		drill = null

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
