extends Interactable
class_name ScreenInteractable

@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@export var screen: PackedScene

func _ready() -> void:
	subviewport.add_child(screen.instantiate())

func interact(_player: Player):
	Global.set_camera_focus.emit(global_position)