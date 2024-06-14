extends CharacterBody3D

const PLAYER = {
	SPEED = 5.0,
	JUMP_VELOCITY = 12.0
}

const DRILL = {
	LAUNCH_SPEED = 20.0,
}

@onready var drill_scene = preload ("res://src/drill_bit.tscn")
@onready var camera: Camera3D = $Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var drill: RigidBody3D = null

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement(delta)
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_movement(_delta):
	var direction = Input.get_axis("left", "right")
	velocity.x = direction * PLAYER.SPEED

func jump():
	if is_on_floor():
		velocity.y = PLAYER.JUMP_VELOCITY

func shoot():
	var instance: RigidBody3D = drill_scene.instantiate()
	instance.position = global_position + Vector3(0, 1, 0)
	var vec_to_mouse = (camera.unproject_position(global_position) - get_viewport().get_mouse_position()).normalized()
	instance.apply_central_impulse(Vector3( - vec_to_mouse.x, vec_to_mouse.y, 0) * DRILL.LAUNCH_SPEED)
	get_parent().add_child(instance)
	drill = instance

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump()
	if event.is_action_pressed("repel"):
		shoot()