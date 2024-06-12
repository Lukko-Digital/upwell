extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const DRILL = {
	LAUNCH_SPEED = 600.0
}

@onready var drill_scene = preload ("res://src/drill_bit.tscn")
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var drill = null

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
