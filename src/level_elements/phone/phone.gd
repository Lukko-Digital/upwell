extends Interactable
class_name Phone

@export var dial: Sprite2D
@export var dial_grabbable: Area2D
@export var buttons_container: Node2D

var grabbed: bool = false
var resetting: bool = false
var grab_point: Vector2
var max_angle: float

func _ready() -> void:
	super()
	for button: PhoneNumberButton in buttons_container.get_children():
		button.clicked.connect(_on_button_clicked)

func _process(delta: float) -> void:
	if grabbed:
		dial.rotation = clamp(fposmod(grab_point.angle_to(get_global_mouse_position() - dial.global_position), TAU), 0, max_angle)
	if resetting:
		dial.rotation = move_toward(fposmod(dial.rotation, TAU), 0.0, delta * 10)
		if dial.rotation == 0:
			resetting = false

func tween_dial_rotation(angle: float, time: float, trans: Tween.TransitionType) -> Tween:
	var tween = create_tween()
	tween.tween_property(dial, "rotation", angle, time).set_trans(trans)
	return tween

func _on_button_clicked(button: PhoneNumberButton):
	var angle = fposmod(-dial.global_position.angle_to_point(button.global_position), TAU)
	# await tween_dial_rotation(angle, angle * 0.3 / TAU + 0.2).finished
	await tween_dial_rotation(
		angle,
		angle * 0.4 / TAU + 0.2,
		Tween.TRANS_CUBIC
	).finished
	await get_tree().create_timer(0.2).timeout
	tween_dial_rotation(0, angle * 1.5 / TAU, Tween.TRANS_LINEAR, )
	# tween_dial_rotation(0, angle * 1.5 / TAU)

func grab(button: PhoneNumberButton):
	if resetting:
		return
	grabbed = true
	grab_point = get_global_mouse_position() - dial.global_position
	max_angle = fposmod(-dial.global_position.angle_to_point(button.global_position), TAU)

func release():
	grabbed = false
	resetting = true
	# await tween_dial_rotation(0, fposmod(dial.rotation, TAU) * 1.5 / TAU).finished
	# resetting = false

# func _on_dial_grabbable_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
# 	if (
# 		event is InputEventMouseButton and
# 		event.button_index == MOUSE_BUTTON_LEFT and
# 		event.pressed
# 	):
# 		grab()

func _input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		not event.pressed
	):
		if grabbed:
			release()
