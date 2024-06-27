extends GravitizedBody
class_name ClickerBody

const MAX_FALL_SPEED = 2600
const BOUNCE_AMOUNT = 0.3

func _physics_process(delta: float) -> void:
	var gravity_state: GravityState = handle_artificial_gravity(delta)
	handle_world_gravity(delta, gravity_state, MAX_FALL_SPEED)
	handle_nudge(gravity_state)

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_AMOUNT

func handle_artificial_gravity(delta: float):
	if !Global.player_has_clicker:
		return GravityState.NONE
	return super(delta)