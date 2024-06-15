extends Resource
class_name Response

var response_text: String
var spawn_time: float
var despawn_time: float
var next_branch_id: String

func _init(response_text_: String, spawn_time_: float, despawn_time_: float, next_branch_id_: String) -> void:
	response_text = response_text_
	spawn_time = spawn_time_
	despawn_time = despawn_time_
	next_branch_id = next_branch_id_

func print():
	print("\t\t\t\tresponse_text: ", response_text)
	print("\t\t\t\tspawn_time: ", spawn_time)
	print("\t\t\t\tdespawn_time: ", despawn_time)
	print("\t\t\t\tnext_branch_id: ", next_branch_id)