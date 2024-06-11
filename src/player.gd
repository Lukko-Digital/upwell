extends CharacterBody2D

const SPEED = 60.0

enum MODE {
	TOP_DOWN,
	SIDE_SCROLL
}

@onready var sprite = $AnimatedSprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var idle_dir: Vector2 = Vector2.DOWN
var mode = MODE.SIDE_SCROLL

func _physics_process(delta):
	handle_gravity(delta)
	var input_dir = handle_movement()
	handle_animation(input_dir)
	move_and_slide()

func handle_gravity(delta):
	if mode == MODE.SIDE_SCROLL:
		velocity.y += gravity * delta

func handle_movement() -> Vector2:
	var direction: Vector2 = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down") if mode == MODE.TOP_DOWN else 0.0
	)
	match mode:
		MODE.TOP_DOWN:
			velocity = direction.normalized() * SPEED
		MODE.SIDE_SCROLL:
			velocity.x = direction.x * SPEED
	return direction

func handle_animation(input_dir):
	match input_dir:
		Vector2.ZERO:
			if idle_dir == Vector2.DOWN:
				sprite.play("idle_down")
			else:
				sprite.play("idle_up")
		# down diag and horizontal
		Vector2.RIGHT, Vector2(1, 1), Vector2.LEFT, Vector2( - 1, 1):
			sprite.play("run_down_right")
		# up diag
		Vector2(1, -1), Vector2( - 1, -1):
			sprite.play("run_up_right")
		Vector2.DOWN:
			sprite.play("run_down")
		Vector2.UP:
			sprite.play("run_up")
	
	if input_dir.x < 0:
		sprite.flip_h = true
	else: sprite.flip_h = false
	
	if input_dir.y < 0:
		idle_dir = Vector2.UP
	elif input_dir:
		idle_dir = Vector2.DOWN

func swap_mode():
	if mode == MODE.TOP_DOWN:
		mode = MODE.SIDE_SCROLL
	else:
		mode = MODE.TOP_DOWN

func _on_area_2d_area_entered(area: Area2D):
	if area is ModeSwap:
		swap_mode()