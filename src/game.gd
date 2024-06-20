extends Control
class_name Game

@export var map_canvas_layer: CanvasLayer
@export var map: Map

@onready var active_level: Node = $ActiveLevel
@onready var map_player: MapPlayer = map.get_node("MapPlayer")

func change_level(level: PackedScene):
	var current_level = active_level.get_child(0)
	active_level.remove_child(current_level)
	current_level.queue_free()
	var new_level = level.instantiate()
	active_level.add_child(new_level)

# Returns true if map is visable and false if not
func toggle_map() -> bool:
	if not map_player.moving:
		map_canvas_layer.visible = !map_canvas_layer.visible
	return map_canvas_layer.visible