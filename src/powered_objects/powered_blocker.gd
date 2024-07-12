extends PoweredObjected
class_name PoweredBlocker

@export var blocker: ClickerBlocker

func power_on():
    blocker.enable()

func power_off():
    blocker.disable()