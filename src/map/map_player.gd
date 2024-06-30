extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

@onready var coolant_bar: ProgressBar = $CanvasLayer/Coolant
@onready var heat_bar: ProgressBar = $CanvasLayer/Heat
@onready var starting_position: Vector2 = global_position

var moving = false
var destination: MapLevel

var drill_heat: float = 0:
	set(value):
		drill_heat = value
		Global.drill_heat = value
		heat_bar.value = value

const SPEED: float = 200
const HEAT_RATE: float = 25
const COOL_RATE: float = 5
const COOLANT_USE_RATE = 25

func _process(delta: float) -> void:
	if moving:
		global_position = global_position.move_toward(destination.global_position, SPEED * delta)
		if global_position.distance_to(destination.global_position) < 1:
			end_movement()
		else:
			line.set_point_position(1, destination.global_position - global_position)

		if coolant_bar.value > 0:
			coolant_bar.value -= delta * COOLANT_USE_RATE
			if drill_heat < Global.MEDIUM_DRILL_HEAT:
				drill_heat += delta * HEAT_RATE
		elif drill_heat < heat_bar.max_value:
			drill_heat += delta * HEAT_RATE

	elif drill_heat > 0:
		drill_heat -= delta * COOL_RATE

	if heat_bar.value == heat_bar.max_value:
		recall()

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
	if moving or drill_heat > 0:
		return
	destination = location
	moving = true

func enter_coolant_pocket() -> void:
	drill_heat = 0

func end_movement() -> void:
	moving = false
	if line.get_point_count() > 1:
		line.remove_point(1)

func recall() -> void:
	global_position = starting_position
	drill_heat = 0
	coolant_bar.value = coolant_bar.max_value
	end_movement()