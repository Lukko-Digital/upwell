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
	ATTRACT_FORCE = 400.0,
	INITIAL_ATTRACT_SPEED = 300.0
}

@onready var drill_scene = preload ("res://src/drill_bit.tscn")
@onready var pickup_area: Area2D = $PickupArea

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var drill: RigidBody2D = null

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement(delta):
	# magnet attraction
	if drill:
		var vec_to_drill = (drill.global_position - global_position).normalized()
		if Input.is_action_pressed("down"):
			if Input.is_action_pressed("attract"):
				drill.set_axis_velocity( - vec_to_drill * DRILL.ATTRACT_FORCE)
				# drill.apply_central_force( - vec_to_drill * DRILL.ATTRACT_FORCE * 4)
		else:
			if Input.is_action_just_pressed("attract"):
				velocity += vec_to_drill * DRILL.INITIAL_ATTRACT_SPEED
			if Input.is_action_pressed("attract"):
				velocity += vec_to_drill * DRILL.ATTRACT_FORCE * delta
		if drill in pickup_area.get_overlapping_bodies() and Input.is_action_pressed("attract"):
			drill.queue_free()
			drill = null

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

func shoot():
	if drill:
		return
	var instance: RigidBody2D = drill_scene.instantiate()
	instance.position = global_position
	instance.apply_central_impulse((get_global_mouse_position() - global_position).normalized() * DRILL.LAUNCH_SPEED)
	get_parent().add_child(instance)
	drill = instance

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	elif event.is_action_pressed("shoot"):
		shoot()
