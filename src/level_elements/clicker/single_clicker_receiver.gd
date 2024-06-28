extends ClickerHolder
class_name SingleClickerReceiver

@export var unlocks_level: Global.LevelIDs

func _set_has_clicker(value: bool):
	super(value)
	if has_clicker and unlocks_level:
		Global.unlock_level(unlocks_level)
