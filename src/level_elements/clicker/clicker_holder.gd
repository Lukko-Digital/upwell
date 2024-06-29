extends Interactable
class_name ClickerHolder

@export var starts_with_clicker: bool
@export var clicker_sprite: Sprite2D

@onready var id: String = owner.name + name
@onready var clicker_scene: PackedScene = preload ("res://src/level_elements/clicker/clicker.tscn")

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

func drop_clicker(clicker_parent: Node2D):
	if !has_clicker:
		return
	has_clicker = false
	var instance: ClickerBody = clicker_scene.instantiate()
	instance.global_position = clicker_sprite.global_position
	instance.catchable = false
	clicker_parent.add_child(instance)

func _set_has_clicker(value: bool):
	clicker_sprite.visible = value
	has_clicker = value
	Global.clicker_state[id] = value
	clicker_state_changed.emit(self, value)
