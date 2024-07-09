extends RigidBody2D
class_name ClickerBody

@export var grav_component: GravitizedComponent

## Set false when dropped to prevent immediately re-entering holder
var catchable = true

func _physics_process(delta: float) -> void:
	var gravity_state: GravitizedComponent.GravityState = handle_artificial_gravity(delta)
	if gravity_state == GravitizedComponent.GravityState.ORBIT:
		gravity_scale = 0
	else:
		gravity_scale = 1

func handle_artificial_gravity(delta) -> GravitizedComponent.GravityState:
	var active_ag = grav_component.check_active_ag()
	var gravity_state = grav_component.determine_gravity_state(active_ag)
	if gravity_state != GravitizedComponent.GravityState.NONE:
		var new_vel = grav_component.calculate_gravitized_velocity(
			active_ag, gravity_state, linear_velocity, delta
		)
		linear_velocity = new_vel
	return gravity_state

func _on_holder_detector_area_entered(area: Area2D) -> void:
	if not area is ClickerHolder:
		return
	if (
		not catchable or
		not area.is_catcher or
		area.has_clicker
	):
		return

	area.has_clicker = true
	queue_free()
