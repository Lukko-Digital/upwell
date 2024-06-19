extends Interactable
class_name ClickerHolder

@export var has_clicker: bool = true:
	set(value):
		$Clicker.visible = value
		has_clicker = value

@onready var id: String = owner.name + name

func _ready():
	if id not in Global.clicker_state:
		# Add state to Global state
		Global.clicker_state[id] = has_clicker
	else:
		# Load from Global state
		has_clicker = Global.clicker_state[id]

func interact(player: Player):
	if has_clicker != player.has_clicker:
		player.has_clicker = has_clicker
		has_clicker = !has_clicker
		Global.clicker_state[id] = has_clicker
		get_tree().call_group("AGs", "enable")
