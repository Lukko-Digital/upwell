extends CanvasLayer
class_name ClickerUI

@export var player: Player
@export var reactor: Control
@export var clicker_big_sprite: Sprite2D
@export var clicker_small_sprite_1: Sprite2D
@export var clicker_small_sprite_2: Sprite2D
@export var reactor_animation: AnimationPlayer
@export var screen_color_animation: AnimationPlayer
@export var clicker_big_animation: AnimationPlayer

# Map from [Sprite2D] to [Tween]
var existing_tweens = {}

func _ready() -> void:
	for sprite in [clicker_big_sprite, clicker_small_sprite_1, clicker_small_sprite_2]:
		sprite.show()
		sprite.modulate = Color(Color.WHITE, 0)
	player.clicker_count_changed.connect(_player_clicker_count_changed)
	Global.clicker_sent_home.connect(_on_clicker_sent_home)
	Global.camera_focus_changed.connect(_on_camera_focus_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("orbit"):
		clicker_big_sprite.orbitting = true
		tween_visible(clicker_big_sprite.get_child(0), 1, 1, 0.5)
	if event.is_action_released("orbit"):
		clicker_big_sprite.orbitting = false
		tween_visible(clicker_big_sprite.get_child(0), 0, 1, 0.5)
	if event.is_action_pressed("jump") and Input.is_action_pressed("orbit"):
			print("boosted")
			clicker_big_animation.stop()
			clicker_big_animation.play("boost")

func update_clicker_inventory(increased: bool):
	match player.clicker_inventory.size():
		0:
			if not increased:
				reactor_animation.stop()
				reactor_animation.play("drop_last_node")
			tween_visible(clicker_big_sprite, 0)
		1:
			if increased:
				reactor_animation.stop()
				reactor_animation.play("pickup_first_node")
			tween_visible(clicker_big_sprite, 1)
			tween_visible(clicker_small_sprite_1, 0)
		2:
			if increased:
				reactor_animation.stop()
				reactor_animation.play("pickup_new_node")
			tween_visible(clicker_small_sprite_1, 1)
			tween_visible(clicker_small_sprite_2, 0)
		3:
			if increased:
				reactor_animation.stop()
				reactor_animation.play("pickup_new_node")
			tween_visible(clicker_small_sprite_2, 1)

func tween_visible(
	sprite: Sprite2D,
	make_visible: bool,
	self_only: bool = 0,
	duration: float = 0.25
) -> void:
	if existing_tweens.has(sprite):
		existing_tweens[sprite].kill()

	var modulation_type: String
	var target_color: Color

	if self_only:
		modulation_type = "self_modulate"
	else:
		modulation_type = "modulate"
	
	if make_visible:
		target_color = Color(1, 1, 1, 1)
	else:
		target_color = Color(1, 1, 1, 0)
	
	var tween = create_tween()
	tween.tween_property(sprite, modulation_type, target_color, duration)

	existing_tweens[sprite] = tween

func _player_clicker_count_changed(increased: bool):
	update_clicker_inventory(increased)

func _on_clicker_sent_home():
	screen_color_animation.play("flash")

func _on_camera_focus_changed(focus: Node2D):
	if focus == null:
		var tween = create_tween()
		tween.tween_property(reactor, "modulate", Color(Color.WHITE, 1), 0.25)
	elif focus is ScreenInteractable:
		var tween = create_tween()
		tween.tween_property(reactor, "modulate", Color(Color.WHITE, 0), 0.25)