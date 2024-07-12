extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

@onready var energy_bar: ProgressBar = $CanvasLayer/Energy
@onready var starting_position: Vector2 = global_position
@onready var collision_box: Area2D = $PlayerBody
@onready var out_of_energy: Label = $CanvasLayer/OutOfEnergyLabel

var moving = false
var velocity: Vector2 = Vector2.ZERO

var destination: MapLevel = null:
	set(value):
		destination = value
		velocity = global_position.direction_to(value.global_position) * SPEED

const SPEED: float = 200
const ENERGY_USE_RATE: float = 50

const AG_ACCELERATION: float = 4

func _process(delta: float) -> void:
	if moving:
		handle_artificial_gravity(delta)
		global_position += velocity * delta
		if global_position.distance_to(destination.global_position) < 5:
			end_movement()
		else:
			line.set_point_position(1, destination.global_position - global_position)

		energy_bar.value -= ENERGY_USE_RATE * delta
	
	if energy_bar.value <= 0:
		recall()
	elif energy_bar.value == energy_bar.max_value / 2: # For energy warning
		pass

# Return true if attracting or repelling, false otherwise
func handle_artificial_gravity(delta):
	# Check in moving
	if not moving:
		return

	# Check for clicker
	if not Global.player_has_clicker:
		return

	# Check that player is in an AG
	var gravity_regions: Array[ArtificialGravity] = []
	for area in collision_box.get_overlapping_areas():
		if area is ArtificialGravity:
			gravity_regions.append(area)
	if gravity_regions.is_empty():
		return
	
	# Check the AG is enabled
	var gravity_well: ArtificialGravity = gravity_regions[0]
	if not gravity_well.enabled:
		return
	
	var vec_to_gravity = gravity_well.global_position - global_position

	# Check the player is inputting a mouse click
	var attracting = Input.is_action_pressed("attract")
	var repelling = Input.is_action_pressed("repel")
	if not (attracting or repelling):
		return

	match gravity_well.type:
		ArtificialGravity.AGTypes.PUSHPULL:
			# Push and pull
			var active_direction = Vector2.ZERO
			if attracting:
				active_direction += vec_to_gravity.normalized()
			if repelling:
				active_direction += - vec_to_gravity.normalized()
			velocity = velocity.lerp(
				active_direction * SPEED,
				AG_ACCELERATION * delta
			)

		ArtificialGravity.AGTypes.ORBIT:
			# Orbit
			var active_direction = Vector2.ZERO
			if attracting:
				# Right click, clockwise
				active_direction = vec_to_gravity.orthogonal().normalized()
			if repelling:
				# Left click, counterclockwise
				active_direction = -vec_to_gravity.orthogonal().normalized()
			velocity = active_direction * SPEED

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