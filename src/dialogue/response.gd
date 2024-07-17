extends Resource
class_name Response

var response_text: String
## Key of global dialogue conditions
var spawn_condition: String
## Set in the csv by prefixing condition with ! or not
var expected_condition_value: bool
var spawn_time: float
var despawn_time: float
## Key of global dialogue conditions
var variable_to_set: String
var variable_value: bool
var next_branch_id: String

func _init(
	response_text_: String,
	spawn_condition_: String,
	expected_condition_value_: bool,
	spawn_time_: float,
	despawn_time_: float,
	variable_to_set_: String,
	variable_value_: bool,
	next_branch_id_: String
) -> void:
	response_text = response_text_
	spawn_condition = spawn_condition_
	expected_condition_value = expected_condition_value_
	spawn_time = spawn_time_
	despawn_time = despawn_time_
	variable_to_set = variable_to_set_
	variable_value = variable_value_
	next_branch_id = next_branch_id_

func print():
	print("\t\t\tresponse_text: ", response_text)
	print("\t\t\tspawn_condition: ", spawn_condition)
	print("\t\t\tspawn_time: ", spawn_time)
	print("\t\t\tdespawn_time: ", despawn_time)
	print("\t\t\tvariable_to_set: ", variable_to_set)
	print("\t\t\tvariable_value: ", variable_value)
	print("\t\t\tnext_branch_id: ", next_branch_id)