extends CharacterBody2D
## The parent class for a body affected by artificial gravity fields
##
## This class provides functions that are meant to be run in the main physics
## loop, but does not implement [_physics_process]. The methods of this parent
## class are meant to be used in the [_physics_process] of a child class.
class_name GravitizedBody

const ARTIFICIAL_GRAVITY = {
	PUSHPULL_SPEED = 3000.0,
	ACCELERATION = 4.0, # lerp acceleration, unitless
	ORBIT_SPEED = 1500.0,
	BOOST_VELOCITY = 3000.0,
	NUDGE_DISTANCE = 50.0,
	NUDGE_ACCELERATION = 0.1, # lerp acceleration, unitless
}

enum GravityState {NONE, PUSHPULL, ORBIT}

@export var nudge_sprites: Node2D
@export var gravity_detector: Area2D

var world_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var nudge_position: Vector2 = Vector2.ZERO:
	set(value):
		nudge_sprites.position = value
		nudge_position = value

var speed_coef: float = 1

## Handles the movement of the [GravitizedBody] within an AG field.
##
## Detects inputs and checks space for AGs, then updates the [GravitizedBody]'s
## velocity accordingly.
##
## Returns: A [GravityState] representing how the [GravitizedBody] is
## 			currently interacting with AG fields
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

	# Boost
	if Input.is_action_just_pressed("boost"):
		velocity = (-vec_to_gravity + nudge_position).normalized() * ARTIFICIAL_GRAVITY.BOOST_VELOCITY * speed_coef
		gravity_well.disable()
		return GravityState.NONE

	# Check the player is inputting a mouse click
	var attracting = Input.is_action_pressed("attract")
	var repelling = Input.is_action_pressed("repel")
	if not (attracting or repelling):
		return GravityState.NONE

	match gravity_well.type:
		ArtificialGravity.AGTypes.PUSHPULL:
			# Push and pull
			var active_direction = Vector2.ZERO
			if attracting:
				active_direction += vec_to_gravity.normalized()
			if repelling:
				active_direction += (-vec_to_gravity + nudge_position).normalized()
			velocity = velocity.lerp(
				active_direction * ARTIFICIAL_GRAVITY.PUSHPULL_SPEED * speed_coef,
				ARTIFICIAL_GRAVITY.ACCELERATION * delta
			)
			return GravityState.PUSHPULL

		ArtificialGravity.AGTypes.ORBIT:
			# Orbit
			var active_direction = Vector2.ZERO
			if attracting:
				# Right click, clockwise
				active_direction = vec_to_gravity.orthogonal().normalized()
			if repelling:
				# Left click, counterclockwise
				active_direction = -vec_to_gravity.orthogonal().normalized()
			velocity = active_direction * ARTIFICIAL_GRAVITY.ORBIT_SPEED * speed_coef
			return GravityState.ORBIT
	return GravityState.NONE

## Applies constant downward world gravity, up to a max fall speed.
## If the [GravitizedBody] is currently orbiting, world gravity is not applied.
func handle_world_gravity(delta: float, gravity_state: GravityState, max_fall_speed: float):
	if gravity_state == GravityState.ORBIT:
		return
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, max_fall_speed, world_gravity * delta)

## Handles "nudge" movements while in a push-pull AG.
## Allows more precise movement when in the center of an AG.
##
## Returns: A boolean representing if the body is currently being nudged.
func handle_nudge(gravity_state: GravityState) -> bool:
	if gravity_state == GravityState.PUSHPULL:
		var nudge_input = Input.get_vector("left", "right", "up", "down")
		nudge_position = nudge_position.lerp(
			nudge_input * ARTIFICIAL_GRAVITY.NUDGE_DISTANCE,
			ARTIFICIAL_GRAVITY.NUDGE_ACCELERATION
		)
		return true
	else:
		nudge_position = nudge_position.lerp(Vector2.ZERO, ARTIFICIAL_GRAVITY.NUDGE_ACCELERATION)
		return false