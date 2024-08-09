extends Node2D

@export var animation_player: AnimationPlayer

@export var map_player: MapPlayer

@export_category("SPRITES")

@export var backer: Sprite2D
@export var dot_parent: Sprite2D
@export var dot_1: Sprite2D
@export var dot_2: Sprite2D
@export var dot_3: Sprite2D
@export var text_launch: Sprite2D
@export var text_launch_glow: Sprite2D
@export var starsmall: Sprite2D
@export var starmed: Sprite2D
@export var starbig: Sprite2D
@export var scaler: Sprite2D
@export var cross: Sprite2D

var existing_tweens = {}

var pressing: bool = false

const TRANSPARENT: Color = Color(1,1,1,0)
const OPAQUE: Color = Color(1,1,1,1)

const STARS_OFFSET_ON_ARRIVAL: float = 360

func _ready():
	map_player.arrived.connect(_on_arrival)

	text_launch.visible = true
	text_launch_glow.visible = true
	text_launch_glow.modulate = TRANSPARENT
	cross.visible = true
	cross.modulate = TRANSPARENT
	dot_parent.visible = true
	dot_parent.modulate = TRANSPARENT

func _on_launch_button_button_down():
	tween_property(scaler, "scale", Vector2.ONE*0.9, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)

func _on_launch_button_button_up():
	tween_property(scaler, "scale", Vector2.ONE, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT)

func _on_launch_button_pressed():
	if map_player.moving:
		return

	var dur: float = 1

	if map_player.destination == null or map_player.is_destination_reached():
		var special_dur: float = 0.1

		tween_property(text_launch, "modulate", TRANSPARENT, special_dur/2)
		await get_tree().create_timer(special_dur/2).timeout
		tween_property(cross, "modulate", OPAQUE, special_dur)
		await get_tree().create_timer(special_dur).timeout
		tween_property(cross, "modulate", TRANSPARENT, special_dur)
		await get_tree().create_timer(special_dur).timeout
		tween_property(cross, "modulate", OPAQUE, special_dur)
		await get_tree().create_timer(special_dur).timeout
		tween_property(cross, "modulate", TRANSPARENT, special_dur)
		await get_tree().create_timer(special_dur).timeout
		tween_property(text_launch, "modulate", OPAQUE, special_dur)
		return
	
	loading(true)

	if not pressing:
		dur = 2
		mod_360_all_stars()
		rotate_all_stars(
			[
				720+STARS_OFFSET_ON_ARRIVAL,
				-720-STARS_OFFSET_ON_ARRIVAL,
				360+STARS_OFFSET_ON_ARRIVAL
			],
			dur, Tween.TRANS_CUBIC, Tween.EASE_OUT
			)
		
		pressing = true
		await get_tree().create_timer(dur).timeout
		pressing = false

func _on_arrival() -> void:

	## Kill loading
	loading(false)

	await get_tree().create_timer(0.1).timeout

	var dur = 1

	## Snap stars back into default position in bouncy way to signify arrival
	rotate_all_stars([0], dur, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	

func _on_launch_button_mouse_entered():
	var dur: float = 1.0

	tween_property(text_launch_glow, "modulate", OPAQUE, dur, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween_property(backer, "scale", Vector2.ONE*1.1, 1, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	if map_player.moving:
		return

	if pressing:
		return
	
	if map_player.destination == null or map_player.is_destination_reached():
		mod_360_all_stars()
		rotate_all_stars([-15, -20, -30], dur, Tween.TRANS_ELASTIC, Tween.EASE_OUT)

		return

	mod_360_all_stars()
	rotate_all_stars([670, 530, 905], dur, Tween.TRANS_CUBIC, Tween.EASE_OUT)

func _on_launch_button_mouse_exited():
	var dur: float = 1.0

	tween_property(text_launch_glow, "modulate", TRANSPARENT)
	tween_property(backer, "scale", Vector2.ONE, dur, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	if map_player.moving:
		return

	if pressing:
		return

	if map_player.destination == null or map_player.is_destination_reached():
		mod_360_all_stars()
		rotate_all_stars([0], dur, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		return

	mod_360_all_stars()
	rotate_all_stars([0], dur, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	pass

func tween_property(
	sprite: Sprite2D,
	property: String,
	target,
	duration: float = 0.25,
	trans_type: Tween.TransitionType = Tween.TRANS_CUBIC,
	ease_type: Tween.EaseType = Tween.EASE_IN_OUT
	) -> void:
	if existing_tweens.has(sprite):
		existing_tweens[sprite].kill()
	
	var tween = create_tween()
	tween.tween_property(sprite, property, target, duration).set_trans(trans_type).set_ease(ease_type)

	existing_tweens[sprite] = tween

func rotate_all_stars(
	targets: Array[float],
	duration: float = 0.25,
	trans_type: Tween.TransitionType = Tween.TRANS_CUBIC,
	ease_type: Tween.EaseType = Tween.EASE_IN_OUT
	):
	assert(targets.size() == 3 or targets.size() == 1, "not enough targets to rotate all stars")
	if targets.size() == 1:
		targets.resize(3)
		targets.fill(targets[0])
	tween_property(starsmall, "rotation_degrees", targets[0], duration, trans_type, ease_type)
	tween_property(starmed, "rotation_degrees", targets[1], duration, trans_type, ease_type)
	tween_property(starbig, "rotation_degrees", targets[2], duration, trans_type, ease_type)

func mod_360(current_rotation: float) -> float:
	return fmod(current_rotation, 360)

func mod_360_all_stars():
	starsmall.rotation_degrees = mod_360(starsmall.rotation_degrees)
	starmed.rotation_degrees = mod_360(starmed.rotation_degrees)
	starbig.rotation_degrees = mod_360(starbig.rotation_degrees)

func loading(enable: bool, duration: float = 0.1) -> void:

	if enable:
		tween_property(text_launch, "modulate", TRANSPARENT, duration)
		await get_tree().create_timer(duration).timeout
		tween_property(dot_parent, "modulate", OPAQUE, duration)
	else:
		tween_property(dot_parent, "modulate", TRANSPARENT, duration)
		await get_tree().create_timer(duration).timeout
		tween_property(text_launch, "modulate", OPAQUE, 3)