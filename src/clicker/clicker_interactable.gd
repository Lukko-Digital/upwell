extends Interactable
class_name ClickerInteractable

@onready var body = get_parent()

func interact(player: Player):
	if player.has_clicker:
		return
	player.has_clicker = true
	body.queue_free()

func interact_condition(player: Player):
	var player_no_clicker = (player.owned_clicker == null)
	var not_in_holder = (body.holder_owned_by == null)
	return player_no_clicker and not_in_holder