extends Area2D
class_name Interactable

@onready var interact_label: Label = $InteractLabel
@onready var opacity_tween: Tween

## If `true`, this interactable is the one currently highlighted by the player
## for interaction
var highlighted: bool = false:
	set = _set_highlighted

func _set_highlighted(value: bool):
		if opacity_tween: opacity_tween.kill()
		opacity_tween = create_tween()
		opacity_tween.tween_property(interact_label, "modulate", Color(Color.WHITE, float(value)), 0.2)
		highlighted = value

func _ready() -> void:
	interact_label.show()
	interact_label.modulate = Color(Color.WHITE, 0)

func interact(_player: Player):
	pass

## The condition in which the object can be interacted with.
## e.g. an empty clicker holder requires the player to have a clicker
func interact_condition(_player: Player) -> bool:
	return true
