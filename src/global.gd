extends Node

var dialogue_conditions = {
	
	#GENERAL
	"HAS_CLICKER": false,
	
	#DAD
	"DAD_MET": false,
	
	#OLD MAN
	"OLD_MET_RELAPSE": false,
	"OLD_MET": false,
	"OLD_KNOWS_TERIN": false,
	"OLD_RLQ1": true,
	
	#LOCATIONS
	"AT_H32_NUCLEAR": false,
	"AT_001_CONTACT": false,
	"AT_002_FALL": false,
	"AT_003_TEST": false,
	"AT_004_RELAPSE": false,
	"AT_005_STORAGE": false,
	"AT_H02_RECURRENCE": false,
	"AT_UNKNOWN": false,
	
	"BEEN_H32_NUCLEAR": false,
	"BEEN_001_CONTACT": false,
	"BEEN_002_FALL": false,
	"BEEN_003_TEST": false,
	"BEEN_004_RELAPSE": false,
	"BEEN_005_STORAGE": false,
	"BEEN_H02_RECURRENCE": false,
	"BEEN_UNKNOWN": false,
	
	"LEFT_HOME": false
}

var pod_has_clicker = false
var pod_position: EmptyPod = null

var moving_on_map = false

signal set_camera_focus(focus: Node2D)
signal pod_called(empty_pod: EmptyPod)

## Used by clicker UI to perform screen flash
signal clicker_sent_home()

func call_pod(empty_pod: EmptyPod):
	pod_position.handle_empty()
	pod_position = empty_pod
	pod_position.handle_empty()
	pod_called.emit(empty_pod)

func _process(delta):
	if (dialogue_conditions["BEEN_001_CONTACT"] or dialogue_conditions["BEEN_002_FALL"] or dialogue_conditions["BEEN_003_TEST"] or dialogue_conditions["BEEN_004_RELAPSE"] or dialogue_conditions["BEEN_005_STORAGE"] or dialogue_conditions["BEEN_H02_RECURRENCE"] or dialogue_conditions["BEEN_UNKNOWN"]):
		dialogue_conditions["LEFT_HOME"] = true
