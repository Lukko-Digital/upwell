extends Node2D
class_name Game

@export var map_canvas_layer: CanvasLayer
@export var map: Map

@onready var pod: Node2D = $Pod
@onready var active_level: Node = $ActiveLevel
# @onready var map_player: MapPlayer = map.get_node("MapPlayer")

func change_level(level: PackedScene):
	var current_level = active_level.get_child(0)
	active_level.remove_child(current_level)
	current_level.queue_free()
	var new_level = level.instantiate()

	var entry_point: EmptyPod

	for node in new_level.get_children():
		## Placeholder for MVP3 so player can spawn on the left, then arrive on the right side subsequently
		if Global.swap_h32_nuclear_entrances and new_level.name == "H32Nuclear":
			if node is EmptyPod and not node.is_entrace:
				entry_point = node
				break
		## end of placeholder code
		if node is EmptyPod and node.is_entrace:
			entry_point = node

	new_level.global_position += pod.global_position - entry_point.global_position

	Global.pod_position = entry_point

	active_level.call_deferred("add_child", new_level)

# Returns true if map is visable and false if not
func toggle_map() -> bool:
	return false
	# if not map_player.moving:
	# 	map_canvas_layer.visible = !map_canvas_layer.visible
	# return map_canvas_layer.visible
