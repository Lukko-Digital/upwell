extends Node2D
class_name Pod

@export var walls_static_body: StaticBody2D
@export var walls_visual: Node2D

func _ready() -> void:
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
