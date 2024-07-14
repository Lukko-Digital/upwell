extends Node
class_name DialogueParser

const MAX_RESPONSES = 2
const DEFUALT = {
	SPAWN_TIME = 1,
	DESPAWN_TIME = INF,
	DIALOGUE_DURATION = INF
}

static func parse_csv(dialogue_file: String, npc_name: String) -> ConversationTree:
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	var keys := file.get_csv_line()

	# Lambda helpers
	var get_key = func(csv_line: PackedStringArray, key: String) -> String:
		var idx = keys.find(key)
		if idx == - 1:
			assert(false, "Error when parsing dialogue, cannot find key " + key)
		return csv_line[idx]

	var conversation_tree = ConversationTree.new(npc_name)
	while not file.eof_reached():
		var line := file.get_csv_line()

		# create responses
		var responses: Array[Response] = []
		for response_num in range(1, MAX_RESPONSES + 1):
			var text = get_key.call(line, "R%s Text" % response_num)
			if text.is_empty():
				break
			var response = Response.new(
				text,
				get_key.call(line, "R%s Spawn Condition" % response_num),
				to_float_or_default(get_key.call(line, "R%s Spawn Time" % response_num), DEFUALT.SPAWN_TIME),
				to_float_or_default(get_key.call(line, "R%s Despawn Time" % response_num), DEFUALT.DESPAWN_TIME),
				get_key.call(line, "R%s Variable To Set" % response_num),
				to_bool(get_key.call(line, "R%s Variable Value" % response_num)),
				error_if_empty(
					get_key.call(line, "R%s Next Branch" % response_num),
					"Error when parsing dialogue, the response \"" + text + "\" has no next branch"
				)
			)
			responses.append(response)

		# create branch
		var branch_id = get_key.call(line, "Branch")
		if branch_id.is_empty():
			# Ignore empty branches, allows for header labels
			continue
		conversation_tree.branches[branch_id] = ConversationBranch.new(
			branch_id,
			get_key.call(line, "Dialogue Text"),
			to_float_or_default(get_key.call(line, "Duration"), DEFUALT.DIALOGUE_DURATION),
			get_key.call(line, "Variable To Set"),
			to_bool(get_key.call(line, "Variable Value")),
			get_key.call(line, "Next Branch"),
			get_key.call(line, "Condition"),
			get_key.call(line, "Conditional Next Branch"),
			responses
		)
	return conversation_tree

static func to_float_or_default(string: String, default: float) -> float:
	if string.is_empty():
		return default
	elif string.is_valid_float():
		return string.to_float()
	else:
		assert(false, "Error when parsing dialogue, tried to convert " + string + " to float")
		return 0

static func to_bool(string: String):
	match string:
		"0": return false
		"1": return true
		"": return false
		_:
			assert(false, "Error when parsing dialogue, tried to convert " + string + " to bool, expected '0' or '1'")

static func error_if_empty(string: String, error_msg: String):
	if string.is_empty():
		assert(false, error_msg)
	else:
		return string
