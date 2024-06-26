extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

@onready var coolant_bar: ProgressBar = $CanvasLayer/Coolant
@onready var heat_bar: ProgressBar = $CanvasLayer/Heat

var moving = false
var destination: MapLevel

const SPEED: float = 400

func _process(delta: float) -> void:
	if moving:
		global_position = global_position.move_toward(destination.global_position, SPEED * delta)

		if global_position.distance_to(destination.global_position) < 1:
			moving = false
			if line.get_point_count() > 1:
				line.remove_point(1)
		else:
			line.set_point_position(1, destination.global_position - global_position)

		if coolant_bar.value > 0:
			coolant_bar.set_deferred("value", coolant_bar.value - delta * 50)
			if heat_bar.value < heat_bar.max_value / 2:
				heat_bar.set_deferred("value", heat_bar.value + delta * 50)
		elif heat_bar.value < heat_bar.max_value:
			heat_bar.set_deferred("value", heat_bar.value + delta * 50)
	else:
		heat_bar.set_deferred("value", heat_bar.value - delta * 10)

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
	if moving:
		return
	destination = location
	moving = true