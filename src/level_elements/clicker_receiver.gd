extends ClickerHolder
class_name ClickerReceiver

@export var unlocks_level: String

func _ready() -> void:
    super()
    has_clicker = false

func _set_has_clicker(value: bool):
    super(value)
    if has_clicker and unlocks_level:
        Global.unlock_level(unlocks_level)