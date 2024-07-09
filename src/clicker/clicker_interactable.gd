extends Interactable
class_name ClickerInteractable

@onready var body = get_parent()

func interact(player: Player):
	player.owned_clicker = body

func interact_condition(player: Player):
	var not_in_holder = (body.holder_owned_by == null)
	return !player.has_clicker() and not_in_holder