extends ClickerHolder
class_name ClickerReceiver

@export var unlocks_level: Global.LevelIDs = Global.LevelIDs.NULL
@export var is_catcher: bool = false

@export var catcher_field: Sprite2D

func _ready() -> void:
	super()
	catcher_field.visible = is_catcher

func _set_has_clicker(value: bool):
	super(value)
	if has_clicker and unlocks_level != Global.LevelIDs.NULL:
		Global.unlock_level(unlocks_level)
