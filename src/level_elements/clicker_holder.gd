extends Interactable
class_name ClickerHolder

@export var has_clicker: bool = true:
	set(value):
		$Clicker.visible = value
		has_clicker = value

func interact(player: Player):
	if has_clicker != player.has_clicker:
		player.has_clicker = has_clicker
		has_clicker = !has_clicker
		get_tree().call_group("AGs", "enable")