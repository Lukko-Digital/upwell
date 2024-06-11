extends CharacterBody2D

const SPEED = 60.0

@onready var sprite = $AnimatedSprite2D

var idle_dir: Vector2 = Vector2.DOWN

func _physics_process(delta):
	handle_movement()
	handle_animation()
	move_and_slide()

func handle_movement():
	var direction = Vector2(
		Input.get_axis("left", "right"), Input.get_axis("up", "down")
	).normalized()
	velocity = direction * SPEED

func handle_animation():
	var direction = velocity.normalized().round()
	match direction:
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
	
	if direction.x < 0:
		sprite.flip_h = true
	else: sprite.flip_h = false
	
	if direction.y < 0:
		print("up")
		idle_dir = Vector2.UP
	elif direction:
		print("down")
		idle_dir = Vector2.DOWN