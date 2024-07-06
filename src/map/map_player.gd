extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

@onready var coolant_bar: ProgressBar = $CanvasLayer/Coolant
@onready var heat_bar: ProgressBar = $CanvasLayer/Heat
@onready var starting_position: Vector2 = global_position
@onready var collision_box: Area2D = $Area2D

var moving = false
var velocity: Vector2 = Vector2.ZERO

var destination: MapLevel = null:
	set(value):
		destination = value
		velocity = global_position.direction_to(value.global_position) * SPEED

var drill_heat: float = 0:
	set(value):
		drill_heat = value
		Global.drill_heat = value
		heat_bar.value = value

const SPEED: float = 200
const HEAT_RATE: float = 50
const COOL_RATE: float = 5
const COOLANT_USE_RATE: float = 25

const AG_ACCELERATION: float = 4

func _process(delta: float) -> void:
	if moving:
		handle_artificial_gravity(delta)
		global_position += velocity * delta
		if global_position.distance_to(destination.global_position) < 5:
			end_movement()
		else:
			line.set_point_position(1, destination.global_position - global_position)

		if coolant_bar.value > 0: # Reduce coolant and heat drill until it reaches medium threshold
			coolant_bar.value -= delta * COOLANT_USE_RATE
			if drill_heat < Global.MEDIUM_DRILL_HEAT:
				drill_heat += delta * HEAT_RATE
		elif drill_heat < heat_bar.max_value: # If no coolant heat drill with no threshold
			drill_heat += delta * HEAT_RATE

	elif drill_heat > 0: # When not moving, cool drill
		drill_heat -= delta * COOL_RATE

	if heat_bar.value == heat_bar.max_value: # Recall when too hot
		recall()

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
	drill_heat = 0

func end_movement() -> void:
	moving = false
	velocity = Vector2.ZERO
	if line.get_point_count() > 1:
		line.remove_point(1)

func recall() -> void:
	# Commented out for playtesting purposes
	# global_position = starting_position 
	drill_heat = 0
	coolant_bar.value = coolant_bar.max_value
	end_movement()