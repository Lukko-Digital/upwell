extends Interactable
class_name Drill

@export var in_wall = false

func interact(player: Player):
	if in_wall:
		# "get in" to drill
		var map_visible = player.game.toggle_map()
		player.in_map = map_visible
	else:
		# Pick up
		player.has_drill = true
		queue_free()

func remove_from_wall(player: Player):
	if in_wall:
		player.has_drill = true
		queue_free()