extends Interactable
class_name ScreenInteractable

@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@export var screen: PackedScene

func _ready() -> void:
	subviewport.add_child(screen.instantiate())

func interact(_player: Player):
	Global.set_camera_focus.emit(global_position)

func _on_body_exited(body: Node2D):
	if body is Player:
		subviewport.physics_object_picking = false

func _on_body_entered(body: Node2D):
	if body is Player:
		subviewport.physics_object_picking = true
