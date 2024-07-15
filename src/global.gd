extends Node

var dialogue_conditions = {
	"LOC_RELAPSE": true,
	"GREETED_RELAPSE": false,
	"GREETED": false,
	"OLD_KNOWS_TERIN": false,
	"RLQ1": true
}

var pod_has_clicker = false
var pod_position: EmptyPod = null

var moving_on_map = false

signal set_camera_focus(focus: Node2D)
signal pod_called(empty_pod: EmptyPod)

func call_pod(empty_pod: EmptyPod):
	pod_position.handle_empty()
	pod_position = empty_pod
	pod_position.handle_empty()
	pod_called.emit(empty_pod)
