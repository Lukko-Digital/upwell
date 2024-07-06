extends GravitizedBody
class_name ClickerBody

const MAX_FALL_SPEED = 2600
const BOUNCE_AMOUNT = 0.3

## Set false when dropped to prevent immediately re-entering holder
var catchable = true
var frames_since_last_collision = 0

func _physics_process(delta: float) -> void:
	var gravity_state: GravityState = handle_artificial_gravity(delta)
	handle_world_gravity(delta, gravity_state, MAX_FALL_SPEED)
	handle_nudge(gravity_state)
	# Apply normal force and friction
	var floor_normal = get_floor_normal()
	if floor_normal != Vector2.UP:
		# On slope, roll
		velocity.x += (floor_normal * world_gravity * delta * 0.8).x
	else:
		# On flat ground, friction
		velocity.x = move_toward(velocity.x, 0, delta * 500)

	var prev_vel = velocity
	var collided = move_and_slide()

	if collided and frames_since_last_collision > 5:
		var collision = get_last_slide_collision()
		velocity = prev_vel.bounce(collision.get_normal()) * BOUNCE_AMOUNT

	if collided:
		frames_since_last_collision = 0
	else:
		frames_since_last_collision += 1

func handle_artificial_gravity(delta: float):
	if !Global.player_has_clicker:
		return GravityState.NONE
	return super(delta)

func _on_holder_detector_area_entered(area: Area2D) -> void:
	if not area is ClickerReceiver:
		return
	if (
		not catchable or
		not area.is_catcher or
		area.has_clicker
	):
		return

	area.has_clicker = true
	queue_free()
