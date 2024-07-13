extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

@onready var energy_bar: ProgressBar = $CanvasLayer/Energy
@onready var starting_position: Vector2 = global_position
@onready var collision_box: Area2D = $PlayerBody
@onready var out_of_energy: Label = $CanvasLayer/OutOfEnergyLabel
@onready var grav_component: GravitizedComponent = $GravitizedComponent

var moving = false:
	set(value):
		moving = value
		Global.moving_on_map = value

var velocity: Vector2 = Vector2.ZERO

var destination: MapLevel = null:
	set(value):
		destination = value
		velocity = global_position.direction_to(value.global_position) * SPEED

const SPEED: float = 800
const ENERGY_USE_RATE: float = 50

const AG_ACCELERATION: float = 4

func _process(delta: float) -> void:
	if moving:
		var active_ag = grav_component.check_active_ag()
		var gravity_state = grav_component.determine_gravity_state(active_ag)
		if gravity_state != GravitizedComponent.GravityState.NONE:
			var new_vel = grav_component.calculate_gravitized_velocity(
				active_ag, gravity_state, velocity, delta
			)
			velocity = new_vel.normalized() * SPEED

		global_position += velocity * delta
		if global_position.distance_to(destination.global_position) < 20:
			end_movement()
		else:
			line.set_point_position(1, destination.global_position - global_position)

		# energy_bar.value -= ENERGY_USE_RATE * delta
	
	if energy_bar.value <= 0:
		recall()
	elif energy_bar.value == energy_bar.max_value / 2: # For energy warning
		pass

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

func enter_coolant_pocket() -> void:
	energy_bar.value = energy_bar.max_value

func end_movement() -> void:
	moving = false
	velocity = Vector2.ZERO
	energy_bar.value = energy_bar.max_value
	starting_position = global_position
	if line.get_point_count() > 1:
		line.remove_point(1)

	await get_tree().create_timer(0.35).timeout
	Global.set_camera_focus.emit(null)

func recall() -> void:
	global_position = starting_position
	end_movement()

	# FOR JOSH
	out_of_energy.show()
	await get_tree().create_timer(1).timeout
	out_of_energy.hide()

func _area_scanned(area: Area2D) -> void:
	if area is MapLevel:
		if not area.locked:
			area.show()