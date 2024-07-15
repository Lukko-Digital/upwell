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

var current_location_name: String

## Placeholder for MVP3 so player can spawn on the left, then arrive on the right side subsequently
var swap_h32_nuclear_entrances = false

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

func update_current_location(location_name: String):
	# Unset last location
	if not current_location_name.is_empty():
		dialogue_conditions["AT_" + current_location_name] = false
	# Set left home
	if location_name != "H32_NUCLEAR":
		dialogue_conditions["LEFT_HOME"] = true
	# Set current location and been
	dialogue_conditions["AT_" + location_name] = true
	dialogue_conditions["BEEN_" + location_name] = true
	current_location_name = location_name

	print(dialogue_conditions)
