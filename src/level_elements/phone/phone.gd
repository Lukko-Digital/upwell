extends Interactable
class_name Phone

const POD_CODE = [1, 1, 1, 1]

@onready var dial: Sprite2D = $RotatableDial
@onready var buttons_container: Node2D = $PhoneNumberButtons
@onready var lights_container: HBoxContainer = $Lights
@onready var receiver_sprite: AnimatedSprite2D = $Receiver
@onready var receiver_glow: Sprite2D = $Receiver/ReceiverGlow
@onready var small_phone_sprite: Sprite2D = $PhoneSmall
@onready var npc_node: NPC = $PhoneNPC

## Set when player first interacts
var player: Player

var focused: bool = false
var rotating: bool = false
var phone_number: Array[int] = []

func _ready() -> void:
	super()
	# Init visuals
	receiver_sprite.play("in")
	receiver_glow.hide()
	# Connect signals
	for button: PhoneNumberButton in buttons_container.get_children():
		button.clicked.connect(_on_button_clicked)

func interact(player_: Player):
	player = player_
	if not focused:
		Global.main_camera.set_focus(self)
		focused = true
		player.active_phone = self
		player.velocity = Vector2.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		tween_opacity(player, 0, 0.2)
		tween_opacity(small_phone_sprite, 0, 0.2)
	else:
		Global.main_camera.set_focus(null)
		focused = false
		player.active_phone = null
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		tween_opacity(player, 1, 0.2)
		tween_opacity(small_phone_sprite, 1, 0.2)

func tween_opacity(node: CanvasItem, opacity: float, time: float):
	var tween = create_tween()
	tween.tween_property(node, "modulate", Color(Color.WHITE, opacity), time)

func tween_dial_rotation(angle: float, time: float, trans: Tween.TransitionType) -> Tween:
	var tween = create_tween()
	tween.tween_property(dial, "rotation", angle, time).set_trans(trans)
	return tween

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
	player.dialogue_ui.start_dialogue(npc_node, 0)
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
		phone_picked()

func _on_phone_area_mouse_entered() -> void:
	receiver_glow.show()

func _on_phone_area_mouse_exited() -> void:
	receiver_glow.hide()
