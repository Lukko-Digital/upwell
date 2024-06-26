extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

var moving = false
var destination: MapLocation
var game: Game

func _ready() -> void:
	var current_scene = get_tree().get_current_scene()
	if current_scene is Game:
		game = current_scene

func _process(_delta: float) -> void:
	if moving:
		line.set_point_position(1, destination.global_position - global_position)

func location_hovered(location: MapLocation):
	if moving:
		return
	if line.get_point_count() < 2:
		line.add_point(location.global_position - global_position)

func location_unhovered(_location: MapLocation):
	if moving:
		return
	if line.get_point_count() > 1:
		line.remove_point(1)

func location_selected(location: MapLocation):
	if moving:
		return
	destination = location
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", location.global_position, 1)
	moving = true
	# await tween.finished
	# location_reached()

func location_reached(location: MapLocation):
	moving = false
	if line.get_point_count() > 1:
		line.remove_point(1)
	game.change_level(location.level)
