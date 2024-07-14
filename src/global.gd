extends Node

var drill_heat: float = 0
const MEDIUM_DRILL_HEAT: float = 25

var pod_has_clicker = false
var clicker_state = {}
var npc_conversation_state = {}
var pod_position: EmptyPod = null

var moving_on_map = false

signal set_camera_focus(focus: Node2D)
signal pod_called(empty_pod: EmptyPod)

func call_pod(empty_pod: EmptyPod):
	pod_position.handle_empty()
	pod_position = empty_pod
	pod_position.handle_empty()
	pod_called.emit(empty_pod)
