extends Interactable
class_name ScreenInteractable

@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@onready var hider: ColorRect = $SubViewportContainer/SubViewport/CanvasLayer/Hider
@export var screen: PackedScene

var focused: bool = false

func _ready() -> void:
	subviewport.add_child(screen.instantiate())
	Global.set_camera_focus.connect(_on_set_focus)

func interact(_player: Player):
	if not focused:
		Global.set_camera_focus.emit(self)
	else:
		Global.set_camera_focus.emit(null)

# func _on_body_exited(body: Node2D):
# 	if body is Player:
# 		subviewport.physics_object_picking = false

# func _on_body_entered(body: Node2D):
# 	if body is Player:
# 		subviewport.physics_object_picking = true

func _on_set_focus(_focus: Node2D):
	if _focus == self:
		focused = true
		subviewport.physics_object_picking = true
		hider.hide()
	else:
		focused = false
		subviewport.physics_object_picking = false
		hider.show()
