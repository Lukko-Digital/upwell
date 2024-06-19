extends Interactable
class_name ClickerHolder

@export var has_clicker: bool = true:
	set(value):
		$Clicker.visible = value
		has_clicker = value
@export var unlocks_level: String

@onready var id: String = owner.name + name

func _ready():
	if id not in Global.clicker_state:
		# Add state to Global state
		Global.clicker_state[id] = has_clicker
	else:
		# Load from Global state
		has_clicker = Global.clicker_state[id]
	
	if unlocks_level and unlocks_level not in Global.level_unlocks:
		Global.level_unlocks[unlocks_level] = false

func interact(player: Player):
	if has_clicker != player.has_clicker:
		# exchange clicker with player
		player.has_clicker = has_clicker
		has_clicker = !has_clicker
		# save global clicker state and level unlocks
		Global.clicker_state[id] = has_clicker
		if has_clicker and unlocks_level:
			Global.level_unlocks[unlocks_level] = true
			print(Global.level_unlocks)
		# enable all AGs
		get_tree().call_group("AGs", "enable")