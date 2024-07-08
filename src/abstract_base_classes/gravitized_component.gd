extends Node2D
## Provides functions that handle a body's interaction with artificial gravity.
## The three provided functions are meant to be called in the physics process
## function on the body that the component is applied to.[br]
## Usage:
## [codeblock]
## var active_ag = grav_component.check_active_ag()
## var gravity_state = grav_component.determine_gravity_state(active_ag)
## if gravity_state != GravitizedComponent.GravityState.NONE:
## 		var new_vel = grav_component.calculate_gravitized_velocity(
## 			active_ag, gravity_state, velocity, delta
## 		)
## 		velocity = new_vel
## [/codeblock]
class_name GravitizedComponent

const ARTIFICIAL_GRAVITY = {
	ACCELERATION = 4.0, # lerp acceleration, unitless
	ORBIT_SPEED = 800.0,
	MIN_ORBIT_RADIUS = 150.0,
	BOOST_VELOCITY = 3000.0,
}

enum GravityState {NONE, BOOST, PUSHPULL, ORBIT}

@export var gravity_detector: Area2D

## -1 = clockwise, 1 = counter-clockwise
var orbit_direction: int

## Checks if the body is currently interacting with an AG.
##  
## Returns: The overlapping [ArtificialGravity] if the player is pressing the
##          orbit button and the overlapping [ArtificialGravity] is enabled.
##          Otherwise returns null.
func check_active_ag() -> ArtificialGravity:
	# Check that orbit button is pressed
	if not Input.is_action_pressed("orbit"):
		return null

	# Check that body is in an AG
	var gravity_regions: Array[Area2D] = gravity_detector.get_overlapping_areas()
	if gravity_regions.is_empty():
		return null

	# Check the AG is enabled
	var active_ag: ArtificialGravity = gravity_regions[0]
	if not active_ag.enabled:
		return null

	return active_ag

## Determines the gravity state of the player based on the active AG's type and
## the player's inputs.
## 
## Returns: A [GravityState] representing how the body is interacting with AGs
func determine_gravity_state(active_ag: ArtificialGravity) -> GravityState:
	if active_ag == null:
		return GravityState.NONE

	if Input.is_action_just_pressed("jump"):
		active_ag.disable()
		return GravityState.BOOST
	
	match active_ag.type:
		ArtificialGravity.AGTypes.ORBIT:
			return GravityState.ORBIT
	
	return GravityState.NONE

## Calculates the body's velocity for the current frame based on current
## velocity and gravity state. Expects active_ag to not be null.
##
## Returns: A [Vector2] representing the velocity that the body should be set
##			to. Returns the zero vector if the gravity state is unaccounted for
##			in the match statement.
func calculate_gravitized_velocity(
	active_ag: ArtificialGravity,
	gravity_state: GravityState,
	current_velocity: Vector2,
	delta: float
) -> Vector2:
	assert(active_ag != null, "Received null for active AG argument")
	var vec_to_gravity = active_ag.global_position - global_position
	match gravity_state:
		GravityState.BOOST:
			return - vec_to_gravity.normalized() * ARTIFICIAL_GRAVITY.BOOST_VELOCITY
		GravityState.ORBIT:
			# Determine orbit direction
			orbit_direction = sign(vec_to_gravity.angle_to(current_velocity))
			# Get radius and set min radius
			var radius = vec_to_gravity.length()
			if radius < ARTIFICIAL_GRAVITY.MIN_ORBIT_RADIUS:
				radius = ARTIFICIAL_GRAVITY.MIN_ORBIT_RADIUS
			# Formula created by fitting curves to sample data points.
			# Works best between speeds of 400 and 1400
			var constant = 87.7 - 19.9 * log(ARTIFICIAL_GRAVITY.ORBIT_SPEED)
			var angle = deg_to_rad(constant + 18.5 * log(radius))
			# Apply velocity
			var active_direction = vec_to_gravity.rotated(angle * orbit_direction).normalized()
			return current_velocity.lerp(
				active_direction * ARTIFICIAL_GRAVITY.ORBIT_SPEED + active_ag.velocity(),
				ARTIFICIAL_GRAVITY.ACCELERATION * delta
			)
		_:
			return Vector2.ZERO
