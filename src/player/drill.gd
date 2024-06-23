extends Interactable
class_name Drill

@export var in_wall = false

func interact(player: Player):
	if in_wall:
		player.game.toggle_map()
	else:
		# Pick up
		player.has_drill = true
		queue_free()

func remove_from_wall(player: Player):
	player.has_drill = true
	queue_free()