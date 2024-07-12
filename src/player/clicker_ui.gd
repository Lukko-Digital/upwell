extends CanvasLayer
class_name ClickerUI

@export var player: Player
@export var clickers_sprite: AnimatedSprite2D
@export var orbit_knob: Sprite2D
@export var pickup_knob: Sprite2D

@onready var animation_player: AnimationPlayer = $Reactor/AnimationPlayer

func _ready() -> void:
	player.clicker_count_changed.connect(_player_clicker_count_changed)
	update_clicker_inventory()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("orbit"):
		var tween = create_tween()
		tween.tween_property(orbit_knob, "rotation_degrees", -180, 0.25)
	if event.is_action_released("orbit"):
		var tween = create_tween()
		tween.tween_property(orbit_knob, "rotation_degrees", 0, 0.25)

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
	animation_player.stop()
	animation_player.play("360")
