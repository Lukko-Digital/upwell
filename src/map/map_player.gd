extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

# func _ready() -> void:
# 	print(line.get_point_count())

func location_hovered(location: MapLocation):
	if line.get_point_count() < 2:
		line.add_point(location.position)

func location_unhovered(location: MapLocation):
	if line.get_point_count() > 1:
		line.remove_point(1)

func location_selected(location: MapLocation):
	pass