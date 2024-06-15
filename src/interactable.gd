extends Area2D
class_name Interactable

@export_file("*.csv") var dialogue_file

@onready var interact_label: Label = $InteractLabel

func _ready() -> void:
	interact_label.hide()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		interact_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		interact_label.hide()