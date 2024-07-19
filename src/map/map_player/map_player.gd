extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

@onready var energy_bar: ProgressBar = $CanvasLayer/Energy
@onready var starting_position: Vector2 = global_position
@onready var collision_box: Area2D = $PlayerBody
@onready var warning_label: Label = $CanvasLayer/WarningLabel
@onready var grav_component: GravitizedComponent = $GravitizedComponent

const HAZARD_TEXT = "RECALLED DUE TO DAMAGE"
const OUT_OF_ENERGY_TEXT = "RECALLED DUE TO ENERGY LOSS"
const LOW_ENERGY_TEXT = "You are low on energy"
const TRAVEL_SHAKE_AMOUNT = 5.0

var current_shake: float = 0.0
var target_shake: float = 0.0
var shake_lerp_speed: float = 1.0

var moving = false:
	set(value):
		moving = value
		Global.moving_on_map = value

var in_coolant = false

var velocity: Vector2 = Vector2.ZERO

var recalled = false

var destination: MapLevel = null:
	set(value):
		destination = value
		velocity = global_position.direction_to(value.global_position) * SPEED

const SPEED: float = 800
const ENERGY_USE_RATE: float = 30

const AG_ACCELERATION: float = 4

func _process(delta: float) -> void:
	if moving:
		var active_ag = grav_component.check_active_ag()
		var gravity_state = grav_component.determine_gravity_state(active_ag)
		if gravity_state != GravitizedComponent.GravityState.NONE and Global.pod_has_clicker:
			var new_vel = grav_component.calculate_gravitized_velocity(
				active_ag, gravity_state, velocity, delta
			)
			velocity = new_vel.normalized() * SPEED

		global_position += velocity * delta
		if global_position.distance_to(destination.global_position) < 20:
			end_movement()
		else:
			line.set_point_position(1, destination.global_position - global_position)

		if not in_coolant: energy_bar.value -= ENERGY_USE_RATE * delta
	
	if energy_bar.value <= 0:
		show_warning(OUT_OF_ENERGY_TEXT)
		recall()
	# elif energy_bar.value <= energy_bar.max_value / 2: # For energy warning
	# 	show_warning(LOW_ENERGY_TEXT)

	#handle shake lerping
	lerp_shake(delta)

## Constantly lerps [current_shake] to a [target_shake] in order for smooth shake change
func lerp_shake(delta: float):
	current_shake = lerp(current_shake, target_shake, delta * shake_lerp_speed)
	if current_shake != target_shake:
		Global.camera_shake.emit(INF, current_shake)

func location_hovered(location: MapLevel):
	if moving:
		return
	if line.get_point_count() < 2:
		line.add_point(location.global_position - global_position)

func location_unhovered(_location: MapLevel):
	if moving:
		return
	if line.get_point_count() > 1:
		line.remove_point(1)

func location_selected(location: MapLevel):
	# Commented out for playtesting purposes
	if moving: # or drill_heat > 0:
		return
	destination = location
	moving = true

	# Begin shake by setting target and regular speed
	shake_lerp_speed = 1
	target_shake = TRAVEL_SHAKE_AMOUNT

func enter_coolant_pocket() -> void:
	energy_bar.value = energy_bar.max_value
	in_coolant = true
	
func exit_coolant_pocket() -> void:
	in_coolant = false

func end_movement() -> void:
	moving = false

	# Increase shape for landing and kill it quickly
	current_shake = shake_lerp_speed * 40
	shake_lerp_speed = 3.0
	target_shake = 0

	velocity = Vector2.ZERO
	energy_bar.value = energy_bar.max_value
	starting_position = global_position
	if line.get_point_count() > 1:
		line.remove_point(1)

	if not recalled:
		# 7/13, josh says dont bump you out of map on arrival
		# await get_tree().create_timer(0.35).timeout
		# Global.set_camera_focus.emit(null)
		recalled = false

func recall() -> void:
	recalled = true
	global_position = starting_position
	end_movement()

func show_warning(warning_text: String) -> void:
	warning_label.text = warning_text
	warning_label.show()
	await get_tree().create_timer(2).timeout
	warning_label.hide()

func hit_hazard() -> void:
	show_warning(HAZARD_TEXT)
	recall()

func _area_scanned(area: Area2D) -> void:
	if area is MapLevel or area is Hazard or area is CoolantPocket:
		if not area.locked:
			area.show()
