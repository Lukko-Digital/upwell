extends Node2D

@export var player: Player
@export var whisper1: NPC
@export var whisper1_end_location: DialogueStandLocation

var whisper1_started: bool = false

func _ready() -> void:
	Global.dialogue_variable_changed.connect(_on_dialogue_variable_changed)

func _process(_delta):
	pass

func _on_whisper_1_start_area_body_entered(body:Node2D) -> void:
	if body is Player and not whisper1_started:
		# var tween = create_tween()
		# tween.tween_property(player.clicker_ui.reactor, "modulate", Color(Color.WHITE, 0), 0.1) # BREAKS HERE
		var default_clicker_ui_layer: int = player.clicker_ui.layer
		player.clicker_ui.layer = 128
		player.init_npc_interaction(whisper1)
		whisper1_started = true
		var tween = create_tween()
		tween.tween_property(player.clicker_ui.reactor, "modulate", Color(Color.WHITE, 0), 1)
		await get_tree().create_timer(1).timeout
		player.clicker_ui.layer = default_clicker_ui_layer

func _on_dialogue_variable_changed(key: String, value: bool):
	if key == "RUN" and value:
		player.scripted_dialogue_location = whisper1_end_location
		var tween = create_tween()
		tween.tween_property(player.clicker_ui.reactor, "modulate", Color(Color.WHITE, 1), 1)
	pass
