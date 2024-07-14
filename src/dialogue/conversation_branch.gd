extends Resource
class_name ConversationBranch

var id: String
var dialogue_line: String
var duration: float
## Key of global dialogue conditions
var variable_to_set: String
var variable_value: bool
var next_branch_id: String
## Key of global dialogue conditions
## Will default to check if the condition is true. Can be prefixed with !, in
## which case will check if the condition is false.
var condition: String
var conditional_next_branch_id: String
var responses: Array[Response]

func _init(
	id_: String,
	dialogue_line_: String,
	duration_: float,
	variable_to_set_: String,
	variable_value_: bool,
	next_branch_id_: String,
	condition_: String,
	conditional_next_branch_id_: String,
	responses_: Array[Response]
 ) -> void:
	id = id_
	dialogue_line = dialogue_line_
	duration = duration_
	variable_to_set = variable_to_set_
	variable_value = variable_value_
	next_branch_id = next_branch_id_
	condition = condition_
	conditional_next_branch_id = conditional_next_branch_id_
	responses = responses_

func print():
	print("branch id: ", id)
	print("\tdialogue_line: ", dialogue_line)
	print("\tduration: ", duration)
	print("\tvariable_to_set: ", variable_to_set)
	print("\tvariable_value: ", variable_value)
	print("\tnext_branch_id: ", next_branch_id)
	print("\tcondition: ", condition)
	print("\tconditional_next_branch_id: ", conditional_next_branch_id)
	var res_idx = 1
	for response in responses:
		print("\t\tresponse ", res_idx)
		response.print()
		res_idx += 1