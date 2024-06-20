extends Interactable
class_name NPC

@export_file("*.csv") var dialogue_file
@export var initial_conversation_id: String

var conversations := {}

func _ready() -> void:
	super()
	parse_csv()
	init_global()

func interact(player: Player):
	player.start_dialogue(self)

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
			var next_conversation_id = get_key.call(line, "next_conversation")
			conversations[conversation_id] = Conversation.new(name, conversation_id, next_conversation_id)

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

func init_global():
	if name not in Global.npc_conversation_state:
		# Add state to Global state
		Global.npc_conversation_state[name] = initial_conversation_id