extends Resource
class_name ConversationBranch

var id: String
## Required
var dialogue_line: String
## Optional
var npc_name: String
## Optional, empty string if not provided. Key of global dialogue conditions.
var variable_to_set: String
## Optional
var variable_value: bool
## Required
var next_branch_id: String
## Optional, empty string if not provided. Key of global dialogue conditions.
var condition: String
## Optional, set in the csv by prefixing condition with ! or not
var expected_condition_value: bool
## Optional
var conditional_next_branch_id: String
## Can be empty
var responses: Array[Response]

func _init(
	id_: String,
	dialogue_line_: String,
	npc_name_: String,
	variable_to_set_: String,
	variable_value_: bool,
	next_branch_id_: String,
	condition_: String,
	expected_condition_value_: bool,
	conditional_next_branch_id_: String,
	responses_: Array[Response]
 ) -> void:
	id = id_
	dialogue_line = dialogue_line_
	npc_name = npc_name_
	variable_to_set = variable_to_set_
	variable_value = variable_value_
	next_branch_id = next_branch_id_
	condition = condition_
	expected_condition_value = expected_condition_value_
	conditional_next_branch_id = conditional_next_branch_id_
	responses = responses_

func print():
	print("branch id: ", id)
	print("\tdialogue_line: ", dialogue_line)
	print("\tnpc_name: ", npc_name)
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