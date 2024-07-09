extends Interactable
class_name ClickerHolder

@export var starts_with_clicker: bool
@export var is_catcher: bool = false
@export var clicker_sprite: Sprite2D
@export var holder_sprite: Sprite2D
@export var catcher_field: Sprite2D

enum HolderFrames {
	GLOW, OFF
}

@onready var id: String = owner.name + name
@onready var clicker_scene: PackedScene = preload ("res://src/clicker/clicker.tscn")

signal clicker_state_changed(holder: ClickerHolder, has_clicker: bool)

var owned_clicker: ClickerBody = null:
	set = _set_owned_clicker

## DEPRECATED, LEFT AS REFERENCE
# func _set_has_clicker(value: bool):
# 	Global.clicker_state[id] = value
# 	## Emit signal (ONLY USED IN MULTIRECEIVER)
# 	clicker_state_changed.emit(self, value)

func _set_owned_clicker(value: ClickerBody):
	if value == null:
		# No clicker
		holder_sprite.frame = HolderFrames.OFF
		if owned_clicker != null:
			# If the holder just lost the clicker, set the lost clicker to no
			# longer be owned by a holder
			owned_clicker.holder_owned_by = null
	else:
		# Has clicker
		holder_sprite.frame = HolderFrames.GLOW
		value.global_position = clicker_sprite.position
		value.freeze = true
		value.holder_owned_by = self
		value.set_parent(self)
	owned_clicker = value
	clicker_state_changed.emit(self, has_clicker())

func _ready():
	super()
	
	if starts_with_clicker:
		var instance: ClickerBody = clicker_scene.instantiate()
		owned_clicker = instance

	catcher_field.visible = is_catcher
	
	## DEPRECATED, LEFT AS REFERENCE
	# if id not in Global.clicker_state:
	# 	# Add state to Global state
	# 	Global.clicker_state[id] = has_clicker
	# else:
	# 	# Load from Global state
	# 	has_clicker = Global.clicker_state[id]

func has_clicker() -> bool:
	return owned_clicker != null

func interact(player: Player):
	# exchange clicker with player
	if has_clicker():
		# holder gives clicker to player
		player.owned_clicker = owned_clicker
		owned_clicker = null
	else:
		# player gives clicker to holder
		owned_clicker = player.owned_clicker
		player.owned_clicker = null

func interact_condition(player: Player):
	return has_clicker() != player.has_clicker()

func drop_clicker(clicker_parent: Node2D):
	if !has_clicker():
		return
	owned_clicker.set_parent(clicker_parent)
	owned_clicker.global_position = clicker_sprite.global_position
	owned_clicker.linear_velocity = Vector2.ZERO
	owned_clicker.catchable = false
	owned_clicker.freeze = false
	owned_clicker = null