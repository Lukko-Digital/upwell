extends Interactable
class_name ClickerHolder

@onready var id: String = owner.name + name

var has_clicker: bool:
	set = _set_has_clicker

func _ready():
	super()
	has_clicker = true
	if id not in Global.clicker_state:
		# Add state to Global state
		Global.clicker_state[id] = has_clicker
	else:
		# Load from Global state
		has_clicker = Global.clicker_state[id]

func interact(player: Player):
	# exchange clicker with player
	player.has_clicker = has_clicker
	has_clicker = !has_clicker

func interact_condition(player: Player):
	return has_clicker != player.has_clicker

func _set_has_clicker(value: bool):
	$ClickerSprite.visible = value
	if value:
		$HookSheet.frame = 0
	else:
		$HookSheet.frame = 1
	has_clicker = value
	Global.clicker_state[id] = value