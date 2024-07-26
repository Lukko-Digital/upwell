extends Node2D
class_name Game

@onready var pod: Node2D = $Pod
@onready var active_level: Node = $ActiveLevel

func change_level(level: PackedScene):
	var current_level = active_level.get_child(0)
	if current_level is Level:
		current_level.save_level_data()
	active_level.remove_child(current_level)
	current_level.queue_free()
	var new_level: Level = level.instantiate()

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

	active_level.add_child.call_deferred(new_level)
	new_level.load_from_level_data.call_deferred()