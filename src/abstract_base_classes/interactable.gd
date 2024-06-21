extends Area2D
class_name Interactable

@onready var interact_label: Label = $InteractLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interact_label.hide()

func interact(_player: Player):
	pass

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		interact_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		interact_label.hide()
