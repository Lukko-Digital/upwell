extends Interactable
class_name Phone

@onready var dial: Sprite2D = $RotatableDial
@onready var buttons_container: Node2D = $PhoneNumberButtons
@onready var lights_container: HBoxContainer = $Lights
@onready var phone_sprite: AnimatedSprite2D = $Phone
@onready var phone_glow: Sprite2D = $Phone/PhoneGlow

var focused: bool = false
var rotating: bool = false
var phone_number: Array[int] = []

func _ready() -> void:
	super()
	# Init visuals
	phone_sprite.play("in")
	phone_glow.hide()
	# Connect signals
	for button: PhoneNumberButton in buttons_container.get_children():
		button.clicked.connect(_on_button_clicked)

func interact(player: Player):
	if not focused:
		Global.main_camera.set_focus(self)
		focused = true
		player.active_phone = self
		player.velocity = Vector2.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var tween = create_tween()
		tween.tween_property(player, "modulate", Color(Color.WHITE, 0), 0.2)
	else:
		Global.main_camera.set_focus(null)
		focused = false
		player.active_phone = null
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		var tween = create_tween()
		tween.tween_property(player, "modulate", Color(Color.WHITE, 1), 0.2)

func tween_dial_rotation(angle: float, time: float, trans: Tween.TransitionType) -> Tween:
	var tween = create_tween()
	tween.tween_property(dial, "rotation", angle, time).set_trans(trans)
	return tween

func number_dialed(number: int):
	phone_number.append(number)
	lights_container.get_child(phone_number.size() - 1).glow()

func _on_button_clicked(button: PhoneNumberButton):
	if rotating or phone_number.size() >= 4:
		return

	rotating = true
	var angle = fposmod(-dial.global_position.angle_to_point(button.global_position), TAU)
	await tween_dial_rotation(angle, angle * 0.4 / TAU + 0.2, Tween.TRANS_CUBIC).finished
	await get_tree().create_timer(0.2).timeout
	number_dialed(button.number)
	await tween_dial_rotation(0, angle * 1.5 / TAU, Tween.TRANS_LINEAR).finished
	rotating = false

func _on_phone_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	):
		phone_number.clear()
		for light: PhoneLight in lights_container.get_children():
			light.unglow()
		phone_sprite.play("out")
		await get_tree().create_timer(0.2).timeout
		phone_sprite.play("in")

func _on_phone_area_mouse_entered() -> void:
	phone_glow.show()

func _on_phone_area_mouse_exited() -> void:
	phone_glow.hide()
