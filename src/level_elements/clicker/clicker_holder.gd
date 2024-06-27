extends Interactable
class_name ClickerHolder

@export var starts_with_clicker: bool
@export var clicker_sprite: Sprite2D
@export var hook_sheet: Sprite2D

@onready var id: String = owner.name + name

signal clicker_state_changed(holder: ClickerHolder, has_clicker: bool)

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

func drop_clicker():
	has_clicker = false

func _set_has_clicker(value: bool):
	clicker_sprite.visible = value
	if value:
		hook_sheet.frame = 0
	else:
		hook_sheet.frame = 1
	has_clicker = value
	Global.clicker_state[id] = value
	clicker_state_changed.emit(self, value)