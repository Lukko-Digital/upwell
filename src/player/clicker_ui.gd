extends CanvasLayer
class_name ClickerUI

@export var player: Player
@export var clicker_big_sprite: Sprite2D
@export var clicker_small_sprite_1: Sprite2D
@export var clicker_small_sprite_2: Sprite2D
@export var reactor_animation: AnimationPlayer
@export var screen_color_animation: AnimationPlayer

func _ready() -> void:
	player.clicker_count_changed.connect(_player_clicker_count_changed)
	Global.clicker_sent_home.connect(_on_clicker_sent_home)
	update_clicker_inventory()

func _input(event: InputEvent) -> void:
	pass
	if event.is_action_pressed("orbit"):
		clicker_big_sprite.orbitting = true
		tween_visible(clicker_big_sprite.get_child(0), 1, 1, 0.5)
	if event.is_action_released("orbit"):
		clicker_big_sprite.orbitting = false
		tween_visible(clicker_big_sprite.get_child(0), 0, 1, 0.5)

func update_clicker_inventory():
	match player.clicker_inventory.size():
		0:
			if clicker_big_sprite.visible:
				reactor_animation.stop()
				reactor_animation.play("drop_last_node")
			tween_visible(clicker_big_sprite, 0)
			tween_visible(clicker_small_sprite_1, 0)
			tween_visible(clicker_small_sprite_2, 0)
		1:
			if !clicker_big_sprite.visible:
				reactor_animation.stop()
				reactor_animation.play("pickup_first_node")
			tween_visible(clicker_big_sprite, 1)
			tween_visible(clicker_small_sprite_1, 0)
			tween_visible(clicker_small_sprite_2, 0)
		2:
			if clicker_big_sprite.visible:
				reactor_animation.play("pickup_new_node")
			tween_visible(clicker_big_sprite, 1)
			tween_visible(clicker_small_sprite_1, 1)
			tween_visible(clicker_small_sprite_2, 0)
		3:
			if clicker_small_sprite_1.visible:
				reactor_animation.play("pickup_new_node")
			tween_visible(clicker_big_sprite, 1)
			tween_visible(clicker_small_sprite_1, 1)
			tween_visible(clicker_small_sprite_2, 1)

func tween_visible(sprite: Sprite2D, make_visible: bool, self_only: bool = 0, duration: float = 0.25) -> void:
	var modulation_type: String
	var target_color: Color

	if self_only:
		modulation_type = "self_modulate"
	else:
		modulation_type = "modulate"
	
	if make_visible:
		target_color = Color(1,1,1,1)
		sprite.show()
	else:
		target_color = Color(1,1,1,0)
	
	var tween = create_tween()
	tween.tween_property(sprite, modulation_type, target_color, duration)

	if !make_visible:
		await get_tree().create_timer(duration).timeout
		sprite.hide()

func _player_clicker_count_changed():
	update_clicker_inventory()
	# reactor_animation.stop()
	# reactor_animation.play("pickup")

func _on_clicker_sent_home():
	screen_color_animation.play("flash")
