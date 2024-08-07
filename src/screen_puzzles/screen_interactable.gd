extends Interactable
class_name ScreenInteractable

@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@onready var hider: ColorRect = $SubViewportContainer/SubViewport/CanvasLayer/Hider
@onready var VHS_shader: ColorRect = $VHS
@onready var virtual_mouse: Sprite2D = $SubViewportContainer/SubViewport/CanvasLayer/virtual_mouse
@export var screen: PackedScene

var focused: bool = false

var warp_current: float = 0;

var interact_label_tween: Tween

func _ready() -> void:
	subviewport.add_child(screen.instantiate())
	Global.camera_focus_changed.connect(_on_set_focus)
	VHS_shader.material = VHS_shader.material.duplicate()
	# VHS_shader.material.shader = VHS_shader.material.shader.duplicate()

func interact(_player: Player):
	if not focused:
		Global.main_camera.set_focus(self)

		if interact_label_tween: interact_label_tween.kill()
		interact_label_tween = create_tween()
		interact_label_tween.tween_property(interact_label, "modulate", Color(Color.WHITE, 0), 0.2)
	else:
		Global.main_camera.set_focus(null)

		if interact_label_tween: interact_label_tween.kill()
		interact_label_tween = create_tween()
		interact_label_tween.tween_property(interact_label, "modulate", Color(Color.WHITE, 1), 0.2)

# func _on_body_exited(body: Node2D):
# 	if body is Player:
# 		subviewport.physics_object_picking = false

# func _on_body_entered(body: Node2D):
# 	if body is Player:
# 		subviewport.physics_object_picking = true

# Lerps screen warping on VHS filter when focusing on a screen from 0 to chosen target
func lerp_warp_amount(delta: float):
	var target
	if focused:
		target = 0.6
	else:
		target = 0.0
	if target == warp_current:
		pass
	warp_current = lerp(warp_current, target, delta * 2)

func _process(delta):
	# if (was_focused != focused):
	# 	was_focused = focused
	# 	if focused:
	# 		lerp_warp_amount(0.0, 1.0, delta)
	# 	else:
	# 		lerp_warp_amount(1.0, 0.0, delta)
	lerp_warp_amount(delta)
	VHS_shader.material.set_shader_parameter("warp_amount", warp_current)

func _on_set_focus(_focus: Node2D):
	if _focus == self:
		focused = true
		subviewport.physics_object_picking = true
		# hider.hide()
	else:
		focused = false
		subviewport.physics_object_picking = false
		# hider.show()
