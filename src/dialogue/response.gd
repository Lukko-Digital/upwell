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