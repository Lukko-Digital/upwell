extends Node
class_name DialogueParser

const START_BRANCH_TAG = "S1"
const END_TAG = "END"
const CONDITION_INVERSE_PREFIX = "!"
const MAX_RESPONSES = 3
const DEFUALT = {
	SPAWN_TIME = 1,
	DESPAWN_TIME = INF,
	# Default dialogue duration is 1.5x the time it takes to display the line
	DIALOGUE_DURATION = 1.5
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
			
			var spawn_condition = get_key.call(line, "R%s Spawn Condition" % response_num)
			var spawn_time = to_float_or_default(get_key.call(line, "R%s Spawn Time" % response_num), DEFUALT.SPAWN_TIME)
			var despawn_time = to_float_or_default(get_key.call(line, "R%s Despawn Time" % response_num), DEFUALT.DESPAWN_TIME)
			var res_variable_to_set = get_key.call(line, "R%s Variable To Set" % response_num)
			var res_variable_value = get_key.call(line, "R%s Variable Value" % response_num)
			var res_next_branch_id = error_if_empty(
				get_key.call(line, "R%s Next Branch" % response_num),
				"Error when parsing dialogue, the response \"" + text + "\" has no next branch"
			)

			var res_expected_condition_value: bool
			if spawn_condition != "":
				if spawn_condition[0] == CONDITION_INVERSE_PREFIX:
					res_expected_condition_value = false
					spawn_condition = spawn_condition.substr(1)
				else:
					res_expected_condition_value = true

			# Safety check for variable to set
			set_variable_safety_checks(res_variable_to_set, res_variable_value)
			get_variable_safety_checks(spawn_condition)

			var response = Response.new(
				text,
				spawn_condition,
				res_expected_condition_value,
				spawn_time,
				despawn_time,
				res_variable_to_set,
				to_bool(res_variable_value),
				res_next_branch_id
			)
			responses.append(response)

		# create branch
		var branch_id = get_key.call(line, "Branch")
		if branch_id.is_empty():
			# Ignore empty branches, allows for header labels
			continue
		
		var dialogue_line = get_key.call(line, "Dialogue Text")
		var duration = to_float_or_default(get_key.call(line, "Duration"), DEFUALT.DIALOGUE_DURATION)
		var variable_to_set = get_key.call(line, "Variable To Set")
		var variable_value = get_key.call(line, "Variable Value")
		var next_branch_id = get_key.call(line, "Next Branch")
		var condition = get_key.call(line, "Condition")
		var conditional_next_branch_id = get_key.call(line, "Conditional Next Branch")

		# Empty boolean algebra lines will have no duration
		if dialogue_line.is_empty():
			duration = 0

		# Determine condition prefixing
		var expected_condition_value: bool
		if condition != "":
			if condition[0] == CONDITION_INVERSE_PREFIX:
				expected_condition_value = false
				condition = condition.substr(1)
			else:
				expected_condition_value = true
		
		# Safety check for global variables to set
		set_variable_safety_checks(variable_to_set, variable_value)
		get_variable_safety_checks(condition)

		conversation_tree.branches[branch_id] = ConversationBranch.new(
			branch_id,
			dialogue_line,
			duration,
			variable_to_set,
			to_bool(variable_value),
			next_branch_id,
			condition,
			expected_condition_value,
			conditional_next_branch_id,
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

static func set_variable_safety_checks(variable_to_set: String, variable_value: String):
	if not variable_to_set.is_empty() and not Global.dialogue_conditions.has(variable_to_set):
		assert(false, "Issue when parsing dialogue, planning to set variable \"" + variable_to_set + "\" which does not exist in Global.dialogue_conditions")
	if not variable_to_set.is_empty() and variable_value.is_empty():
		assert(false, "Error when parsing dialogue, the variable to set \"" + variable_to_set + "\" has no associated value")

static func get_variable_safety_checks(variable_to_get: String):
	if not variable_to_get.is_empty() and not Global.dialogue_conditions.has(variable_to_get):
		assert(false, "Issue when parsing dialogue, planning to get variable \"" + variable_to_get + "\" which does not exist in Global.dialogue_conditions")
