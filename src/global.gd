extends Node

## NULL is not a level but allows receivers to indicate that they do not unlock
## any level
enum LevelIDs {
	NULL,
	L1A,
	L1B,
	L1BB,
	L1C,
	L2A,
	L2B,
	L2C,
	L3A,
	L3B,
	L3BB,
	L3C,
	L4A,
	L4B,
	L4C,
	START
}

var player_has_clicker = false

var drill_heat: float = 0
const MEDIUM_DRILL_HEAT: float = 25

var clicker_state = {}
var level_unlocks = {}
var npc_conversation_state = {}
var pod_position: EmptyPod = null

var moving_on_map = false

signal set_camera_focus(focus: Node2D)
signal pod_called(empty_pod: EmptyPod)

signal level_unlocked(level_name: EmptyPod)

func unlock_level(level_name: LevelIDs):
	level_unlocks[level_name] = true
	level_unlocked.emit(level_name)

func call_pod(empty_pod: EmptyPod):
	pod_position.handle_empty()
	pod_position = empty_pod
	pod_position.handle_empty()
	pod_called.emit(empty_pod)
