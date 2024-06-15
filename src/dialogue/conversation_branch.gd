extends Resource
class_name ConversationBranch

var id: String
var dialogue_line: String
var duration: float
var next_branch_id: String
var responses: Array[Response]

func _init(id_: String, dialogue_line_: String, duration_: float, next_branch_id_: String, responses_: Array[Response]) -> void:
	id = id_
	dialogue_line = dialogue_line_
	duration = duration_
	next_branch_id = next_branch_id_
	responses = responses_