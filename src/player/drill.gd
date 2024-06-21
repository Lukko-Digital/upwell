extends Interactable
class_name Drill

func interact(player: Player):
	# Pick up
	player.has_drill = true
	queue_free()