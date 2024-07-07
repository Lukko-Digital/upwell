extends RigidBody2D

const ARTIFICIAL_GRAVITY = {
	ACCELERATION = 4.0, # lerp acceleration, unitless
	ORBIT_SPEED = 800.0,
	MIN_ORBIT_RADIUS = 150.0,
	BOOST_VELOCITY = 3000.0,
}

enum GravityState {NONE, BOOST, PUSHPULL, ORBIT}

@export var gravity_detector: Area2D
@onready var ray: RayCast2D = $RayCast2D

## -1 = clockwise, 1 = counter-clockwise
var orbit_direction: int

func _physics_process(delta: float) -> void:
	var gravity_state: GravityState = handle_artificial_gravity(delta)
	if gravity_state == GravityState.ORBIT:
		gravity_scale = 0
	else:
		gravity_scale = 1

func handle_artificial_gravity(delta) -> GravityState:
	# Check that player is in an AG
	var gravity_regions: Array[Area2D] = gravity_detector.get_overlapping_areas()
	if gravity_regions.is_empty():
		return GravityState.NONE
	
	# Check the AG is enabled
	var gravity_well: ArtificialGravity = gravity_regions[0]
	if not gravity_well.enabled:
		return GravityState.NONE
	var vec_to_gravity = gravity_well.global_position - global_position
	var orbitting = Input.is_action_pressed("orbit")
	if not orbitting:
		return GravityState.NONE

	# --- From this point forward, the player is pressing the orbit button ---
	# Boost
	if Input.is_action_just_pressed("jump"):
		linear_velocity = -vec_to_gravity.normalized() * ARTIFICIAL_GRAVITY.BOOST_VELOCITY
		gravity_well.disable()
		return GravityState.BOOST

	match gravity_well.type:
		ArtificialGravity.AGTypes.ORBIT:
			# Determine orbit direction
			orbit_direction = sign(vec_to_gravity.angle_to(linear_velocity))
			# Get radius and set min radius
			var radius = vec_to_gravity.length()
			if radius < ARTIFICIAL_GRAVITY.MIN_ORBIT_RADIUS:
				radius = ARTIFICIAL_GRAVITY.MIN_ORBIT_RADIUS
			# Formula created by fitting curves to sample data points.
			# Works best between speeds of 400 and 1400
			var constant = 87.7 - 19.9 * log(ARTIFICIAL_GRAVITY.ORBIT_SPEED)
			var angle = deg_to_rad(constant + 18.5 * log(radius))
			var active_direction = Vector2.ZERO
			# Apply velocity
			active_direction = vec_to_gravity.rotated(angle * orbit_direction).normalized()
			ray.target_position = active_direction * 1000
			linear_velocity = linear_velocity.lerp(
					active_direction * ARTIFICIAL_GRAVITY.ORBIT_SPEED + gravity_well.velocity(),
					ARTIFICIAL_GRAVITY.ACCELERATION * delta
				)
			return GravityState.ORBIT
	return GravityState.NONE
