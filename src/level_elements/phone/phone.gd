extends Interactable
class_name Phone

const POD_CODE = [1, 1, 1, 1]

# Dial
@onready var dial: Sprite2D = $RotatableDial
@onready var buttons_container: Node2D = $PhoneNumberButtons
@onready var lights_container: HBoxContainer = $Lights
# Receiver
@onready var receiver_sprite: AnimatedSprite2D = $Receiver
@onready var receiver_area: Area2D = $Receiver/ReceiverArea
@onready var receiver_glow: Sprite2D = $Receiver/ReceiverGlow
# Other
@onready var small_phone_sprite: Sprite2D = $PhoneSmall
@onready var npc_node: NPC = $PhoneNPC
@onready var blur: ColorRect = $Blur

var blur_tween: Tween

var default_cursor = load("res://assets/puzzle_elements/temp_mouse.png")
var hovered_cursor = load("res://assets/puzzle_elements/temp_mouse2.png")

## Set when player first interacts
var player: Player

var focused: bool = false
var rotating: bool = false
var phone_number: Array[int] = []

## ------------------------------ CORE ------------------------------

func _ready() -> void:
	super()
	# Init visuals
	receiver_sprite.play("in")
	receiver_glow.hide()
	# Connect signals
	for button: PhoneNumberButton in buttons_container.get_children():
		button.clicked.connect(_on_phone_button_clicked)
		button.mouse_entered.connect(_on_phone_button_mouse_entered)
		button.mouse_exited.connect(_on_phone_button_mouse_exited)
	receiver_area.input_event.connect(_on_receiver_area_input_event)
	receiver_area.mouse_entered.connect(_on_receiver_area_mouse_entered)
	receiver_area.mouse_exited.connect(_on_receiver_area_mouse_exited)

func interact(player_: Player):
	player = player_
	if not focused:
		Global.main_camera.set_focus(self)
		focused = true
		player.active_phone = self
		player.velocity = Vector2.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		tween_opacity(player, 0, 0.2)
		tween_opacity(interact_label, 0, 0.2)
		tween_opacity(small_phone_sprite, 0, 0.2)

		if blur_tween: blur_tween.kill()
		await get_tree().create_timer(.3).timeout
		if blur_tween:
			if blur_tween.is_running(): return
		blur_tween = create_tween()
		blur_tween.tween_property(blur.material, "shader_parameter/blur_amount", 4, 0.3)
	else:
		Global.main_camera.set_focus(null)
		focused = false
		player.active_phone = null
		reset()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		tween_opacity(player, 1, 0.2)
		tween_opacity(interact_label, 1, 0.3)
		tween_opacity(small_phone_sprite, 1, 0.3)

		if blur_tween: blur_tween.kill()
		blur_tween = create_tween()
		blur_tween.tween_property(blur.material, "shader_parameter/blur_amount", 0, 0.2)

## ------------------------------ VISUALS ------------------------------

func tween_opacity(node: CanvasItem, opacity: float, time: float):
	var tween = create_tween()
	tween.tween_property(node, "modulate", Color(Color.WHITE, opacity), time)

func tween_dial_rotation(angle: float, time: float, trans: Tween.TransitionType) -> Tween:
	var tween = create_tween()
	tween.tween_property(dial, "rotation", angle, time).set_trans(trans)
	return tween

## ------------------------------ PHONING ------------------------------

func number_dialed(number: int):
	phone_number.append(number)
	lights_container.get_child(phone_number.size() - 1).glow()

func phone_picked():
	if phone_number.size() < 4:
		reset()
		return
	
	if phone_number == POD_CODE:
		call_pod()
	
	var key = get_phone_number_key()
	if not key.is_empty():
		Global.set_dialogue_variable(key, true)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.dialogue_ui.start_dialogue(npc_node)
	await player.dialogue_ui.dialogue_finished
	reset()

	if not key.is_empty():
		Global.set_dialogue_variable(key, false)

func reset():
	phone_number.clear()
	for light: PhoneLight in lights_container.get_children():
		light.unglow()
	receiver_sprite.play("out")
	await get_tree().create_timer(0.2).timeout
	receiver_sprite.play("in")

func call_pod():
	var parent = get_parent()
	if parent is EmptyPod:
		Global.call_pod(parent)

## Check if the dialed number has a corresponding Global dialogue variable.
## Returns the dictionary key for the dialed number if it exists, or the empty
## string if it doesn't
func get_phone_number_key() -> String:
	var num_string = ""
	for num in phone_number:
		num_string += str(num)
	var key = num_string + "_DIALED"
	if Global.dialogue_conditions.has(key):
		return key
	else:
		return ""

## ------------------------------ CURSOR ------------------------------

func set_hovered_cursor():
	Input.set_custom_mouse_cursor(hovered_cursor, Input.CURSOR_ARROW, Vector2(64, 64))

func set_default_cursor():
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW, Vector2(64, 64))

## ------------------------------ SIGNALS ------------------------------

func _on_phone_button_clicked(button: PhoneNumberButton):
	if rotating or phone_number.size() >= 4:
		return

	rotating = true
	var angle = fposmod(-dial.global_position.angle_to_point(button.global_position), TAU)
	await tween_dial_rotation(angle, angle * 0.4 / TAU + 0.2, Tween.TRANS_CUBIC).finished
	await get_tree().create_timer(0.2).timeout
	number_dialed(button.number)
	await tween_dial_rotation(0, angle * 1.5 / TAU, Tween.TRANS_LINEAR).finished
	rotating = false

func _on_phone_button_mouse_entered():
	set_hovered_cursor()

func _on_phone_button_mouse_exited():
	set_default_cursor()

func _on_receiver_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	):
		phone_picked()

func _on_receiver_area_mouse_entered() -> void:
	receiver_glow.show()
	set_hovered_cursor()

func _on_receiver_area_mouse_exited() -> void:
	set_default_cursor()
