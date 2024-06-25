extends Interactable
class_name ClickerHolder

@export var has_clicker: bool = true:
	set(value):
		$ClickerSprite.visible = value
		if value:
			$HookSheet.frame = 0
		else:
			$HookSheet.frame = 1
		has_clicker = value
@export var unlocks_level: String

@onready var id: String = owner.name + name

func _ready():
	has_clicker = has_clicker # Allows glowing frame on spawn
	super()
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
	# save global clicker state and level unlocks
	Global.clicker_state[id] = has_clicker
	if has_clicker and unlocks_level:
		Global.unlock_level(unlocks_level)
	# enable all AGs
	enable_ags()

func interact_condition(player: Player):
	return has_clicker != player.has_clicker

func enable_ags():
	get_tree().call_group("AGs", "enable")