extends Interactable
class_name ClickerHolder

@export var starts_with_clicker: bool
@export var is_catcher: bool = false

enum HolderFrames {
	OFF, GLOW, HOLDING
}

@onready var clicker_sprite: Sprite2D = %ClickerSprite
@onready var holder_sprite: Sprite2D = %HolderSprite
@onready var catcher_field: Sprite2D = %CatcherField
@onready var clicker_scene: PackedScene = preload("res://src/clicker/clicker.tscn")

signal clicker_state_changed(holder: ClickerHolder, has_clicker: bool)

var owned_clicker: ClickerBody = null:
	set = _set_owned_clicker

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
		holder_sprite.frame = HolderFrames.GLOW
		# ^ it still glows because the player can put it back in
		if has_clicker():
			# If the holder just lost the clicker, set the lost clicker to no
			# longer be owned by a holder
			owned_clicker.holder_owned_by = null
	else:
		# Has clicker
		holder_sprite.frame = HolderFrames.HOLDING
		# Lock clicker to holder
		clicker.set_deferred("global_position", clicker_sprite.global_position)
		clicker.set_deferred("freeze", true)
		clicker.holder_owned_by = self
	owned_clicker = clicker
	clicker_state_changed.emit(self, has_clicker())

func _ready():
	super()
	add_to_group("Holders")
	catcher_field.visible = is_catcher
	## Spawn test clickers
	if not get_tree().get_current_scene() is Game:
		init_starting_clicker()

func init_starting_clicker():
	if starts_with_clicker:
		var instance: ClickerBody = clicker_scene.instantiate()
		instance.home_holder = self
		get_parent().add_child.call_deferred(instance)
		owned_clicker = instance
	else:
		owned_clicker = null
		holder_sprite.frame = HolderFrames.OFF

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
