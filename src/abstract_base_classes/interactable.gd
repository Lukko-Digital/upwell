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
