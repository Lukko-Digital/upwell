extends Node2D
class_name Game

@onready var pod: Node2D = $Pod
# @onready var active_level: Node = $ActiveLevel
@onready var levels: Node2D = $Levels

## The x and y distance that levels spawn away from each other
const LEVEL_DISTANCE = 50000
const LEVEL_GRID_WIDTH = 4

var next_level_spawn_coords = Vector2i.ZERO
## Map from level [PackedScene] to level's root node in [levels]
var level_refs = {}

func init_level(level: PackedScene):
	var new_level: Level = level.instantiate()
	level_refs[level] = new_level
	new_level.position = next_level_spawn_coords * LEVEL_DISTANCE
	# new_level.update_canvas_layer_position()

	if next_level_spawn_coords.x < LEVEL_GRID_WIDTH - 1:
		next_level_spawn_coords.x += 1
	else:
		next_level_spawn_coords.x = 0
		next_level_spawn_coords.y += 1
	
	new_level.process_mode = Node.PROCESS_MODE_DISABLED
	levels.add_child(new_level)

func change_level(level: PackedScene):
	var level_node = level_refs[level]
	level_node.process_mode = Node.PROCESS_MODE_INHERIT
	# var current_level = active_level.get_child(0)
	# active_level.remove_child(current_level)
	# current_level.queue_free()
	# var new_level = level.instantiate()

	var entry_point: EmptyPod

	for node in level_node.get_children():
	# 	## Placeholder for MVP3 so player can spawn on the left, then arrive on the right side subsequently
	# 	if Global.swap_h32_nuclear_entrances and new_level.name == "H32Nuclear":
	# 		if node is EmptyPod and not node.is_entrace:
	# 			entry_point = node
	# 			break
	# 	## end of placeholder code
		if node is EmptyPod and node.is_entrace:
			entry_point = node

	# 		#reposition canvaslayers
	# 		for child in new_level.get_children():
	# 			if child is CanvasLayer:
	# 				for secondChild in child.get_children():
	# 					secondChild.global_position += pod.global_position - entry_point.global_position

	# levels.global_position -= entry_point.global_position
	var vec_to_new_location = entry_point.global_position - pod.global_position
	pod.global_position += vec_to_new_location
	$Player.global_position += vec_to_new_location

	# Global.pod_position = entry_point

	# active_level.call_deferred("add_child", new_level)
