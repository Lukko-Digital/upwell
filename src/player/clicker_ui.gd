extends CanvasLayer
class_name ClickerUI

@export var player: Player
@export var clickers_sprite: AnimatedSprite2D
@export var reactor_animation: AnimationPlayer
@export var screen_color_animation: AnimationPlayer

func _ready() -> void:
	player.clicker_count_changed.connect(_player_clicker_count_changed)
	player.lost_clicker_to_blocker.connect(_player_lost_clicker_to_blocker)
	update_clicker_inventory()

func _input(_event: InputEvent) -> void:
	pass
	# if event.is_action_pressed("orbit"):
	# 	var tween = create_tween()
	# 	tween.tween_property(orbit_knob, "rotation_degrees", -180, 0.25)
	# if event.is_action_released("orbit"):
	# 	var tween = create_tween()
	# 	tween.tween_property(orbit_knob, "rotation_degrees", 0, 0.25)

func update_clicker_inventory():
	match player.clicker_inventory.size():
		0:
			clickers_sprite.hide()
		1:
			clickers_sprite.show()
			clickers_sprite.play("1")
		2:
			clickers_sprite.play("2")
		3:
			clickers_sprite.play("3")

func _player_clicker_count_changed():
	update_clicker_inventory()
	reactor_animation.stop()
	reactor_animation.play("pickup")

func _player_lost_clicker_to_blocker():
	screen_color_animation.play("flash")