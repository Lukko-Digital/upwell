extends Interactable
class_name ClickerInteractable

@onready var body = get_parent()

func _process(_delta: float) -> void:
	rotation = -body.rotation

func interact(player: Player):
	player.add_clicker(body)

func interact_condition(_player: Player):
	var not_in_holder = (body.holder_owned_by == null)
	return not_in_holder