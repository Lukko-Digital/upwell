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

func _set_highlighted(value: bool):
	if !has_clicker():
		if value:
			holder_sprite.frame = HolderFrames.GLOW
		else:
			holder_sprite.frame = HolderFrames.OFF
	super(value)

func _set_owned_clicker(clicker: ClickerBody):
	if clicker == null:
		# No clicker
		# holder_sprite.frame = HolderFrames.OFF
		# ^ it still glows because the player can put it back in
		if has_clicker():
			# If the holder just lost the clicker, set the lost clicker to no
			# longer be owned by a holder
			owned_clicker.holder_owned_by = null
	else:
		# Has clicker
		holder_sprite.frame = HolderFrames.GLOW
		clicker.global_position = clicker_sprite.global_position
		clicker.set_deferred("freeze", true)
		clicker.holder_owned_by = self
	owned_clicker = clicker
	clicker_state_changed.emit(self, has_clicker())

func _ready():
	super()
	
	if starts_with_clicker:
		var instance: ClickerBody = clicker_scene.instantiate()
		instance.home_holder = self
		get_parent().add_child.call_deferred(instance)
		owned_clicker = instance
	else:
		owned_clicker = null

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
	if has_clicker():
		# holder gives clicker to player
		player.add_clicker(owned_clicker)
		owned_clicker = null
	else:
		# player gives clicker to holder
		owned_clicker = player.spawn_clicker()

func interact_condition(player: Player):
	return has_clicker() or player.has_clicker()

func drop_clicker():
	if !has_clicker():
		return
	owned_clicker.global_position = clicker_sprite.global_position
	owned_clicker.linear_velocity = Vector2.ZERO
	owned_clicker.catchable = false
	owned_clicker.freeze = false
	owned_clicker = null