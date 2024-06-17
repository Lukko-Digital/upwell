extends Interactable
class_name ClickerHolder

var has_clicker: bool = true:
	set(value):
		$Clicker.visible = value
		has_clicker = value

func interact(player: Player):
	player.has_clicker = has_clicker
	has_clicker = !has_clicker