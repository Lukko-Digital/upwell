extends Node2D
class_name Pod

func _ready() -> void:
	Global.pod_called.connect(call_pod)

func call_pod(empty_pod: EmptyPod):
	global_position = empty_pod.global_position
