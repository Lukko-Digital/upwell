extends Area2D
class_name Interactable

@export_file("*.csv") var dialogue_file

@onready var interact_label: Label = $InteractLabel

var conversations := {}

func _ready() -> void:
	interact_label.hide()
	parse_csv()

func parse_csv():
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	var keys := file.get_csv_line()
	var get_key = func(csv_line: PackedStringArray, key: String):
		return csv_line[keys.find(key)]

	while not file.eof_reached():
		var line := file.get_csv_line()
		var conversation_id = get_key.call(line, "conversation")

		# create conversation
		if conversation_id not in conversations:
			conversations[conversation_id] = Conversation.new(conversation_id)

		# create responses
		var responses: Array[Response] = []
		var response_line_idx = keys.find("r1")
		while not line[response_line_idx].is_empty():
			responses.append(
				Response.new(
					line[response_line_idx], # id
					float(line[response_line_idx + 1]), # spawn time
					float(line[response_line_idx + 2]) if not line[response_line_idx + 2].is_empty() else INF, # despawn time
					line[response_line_idx + 3], # next branch id
				)
			)
			response_line_idx += 4
			if response_line_idx >= line.size():
				break

		# create branch
		var branch_id = get_key.call(line, "branch")
		conversations[conversation_id].branches[branch_id] = ConversationBranch.new(
			branch_id,
			get_key.call(line, "dialogue"),
			float(get_key.call(line, "duration (multiplier)")),
			get_key.call(line, "next"),
			responses
		)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		interact_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		interact_label.hide()
