extends Interactable
class_name ClickerInteractable

@onready var body = get_parent()

func interact(player: Player):
	if player.has_clicker:
		return
	player.has_clicker = true
	body.queue_free()

func interact_condition(player: Player):
	return !player.has_clicker