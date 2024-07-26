extends Node2D
class_name Pod

@export var pod_holder: ClickerHolder
@export var walls_static_body: StaticBody2D
@export var walls_visual: Node2D
@export var point_focus_marker: Marker2D

@onready var pod_animation_player: AnimationPlayer = $PodAnimationPlayer
@onready var game: Game = get_tree().get_current_scene()

func _ready() -> void:
	pod_holder.clicker_state_changed.connect(_pod_clicker_state_changed)
	Global.pod_called.connect(call_pod)

func _process(_delta: float) -> void:
	if Global.moving_on_map:
		walls_static_body.process_mode = Node.PROCESS_MODE_INHERIT
		walls_visual.show()
	else:
		walls_static_body.process_mode = Node.PROCESS_MODE_DISABLED
		walls_visual.hide()

func call_pod(empty_pod: EmptyPod):
	global_position = empty_pod.global_position

## Set the home of clickers that enter the pod to the pod holder
func _on_pod_clicker_rehome_area_body_entered(body: Node2D) -> void:
	if body is ClickerBody:
		body.home_holder = pod_holder
		if body.get_parent() != self:
			body.reparent.call_deferred(self)
	elif body is Player:
		for clicker: ClickerInfo in body.clicker_inventory:
			clicker.home_holder = pod_holder
			clicker.parent_node = self

func _on_pod_clicker_rehome_area_body_exited(body: Node2D) -> void:
	var current_level = game.active_level.get_child(0)
	if body is ClickerBody:
		if body.get_parent() == self:
			body.reparent.call_deferred(current_level)
	elif body is Player:
		for clicker: ClickerInfo in body.clicker_inventory:
			clicker.parent_node = current_level

func _pod_clicker_state_changed(_holder: ClickerHolder, has_clicker: bool):
	Global.pod_has_clicker = has_clicker
