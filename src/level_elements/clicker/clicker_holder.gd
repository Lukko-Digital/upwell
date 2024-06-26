extends Interactable
class_name ClickerHolder

@export var starts_with_clicker: bool

@onready var id: String = owner.name + name
@onready var clicker_sprite: Sprite2D = $ClickerSprite
@onready var hook_sheet: Sprite2D = $HookSheet

var has_clicker: bool:
	set = _set_has_clicker

func _ready():
	super()
	has_clicker = starts_with_clicker
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
	clicker_sprite.visible = value
	if value:
		hook_sheet.frame = 0
	else:
		hook_sheet.frame = 1
	has_clicker = value
	Global.clicker_state[id] = value
