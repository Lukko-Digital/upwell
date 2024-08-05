extends Node2D

@export var player: Player
@export var fraud: NPC
@export var out_of_the_trees_location: DialogueStandLocation
@export var approach_location: DialogueStandLocation

var scene_started: bool = false

func _ready() -> void:
	Global.dialogue_variable_changed.connect(_on_dialogue_variable_changed)

func _on_dialogue_start_area_body_entered(body: Node2D) -> void:
	if body is Player and not scene_started:
		player.init_npc_interaction(fraud)
		player.scripted_dialogue_location = out_of_the_trees_location
		scene_started = true

func _on_dialogue_variable_changed(key: String, value: bool):
	if key == "APPROACH" and value:
		player.scripted_dialogue_location = approach_location