extends Area2D
class_name Interactable

@onready var interact_label: Label = $InteractLabel

var highlighted: bool = false:
	set(value):
		interact_label.visible = value
		highlighted = value

func _ready() -> void:
	interact_label.hide()

func interact(_player: Player):
	pass

## The condition in which the object can be interacted with.
## e.g. an empty clicker holder requires the player to have a clicker
func interact_condition(_player: Player) -> bool:
	return true