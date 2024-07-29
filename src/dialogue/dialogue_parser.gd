extends Node
class_name DialogueParser

const START_BRANCH_TAG = "S1"
const END_TAG = "END"
const CONDITION_INVERSE_PREFIX = "!"

const MAX_RESPONSES = 3

const DEFUALT = {
	SPAWN_TIME = .8,
	DESPAWN_TIME = INF,
	# Default dialogue duration is 1.2x the time it takes to display the line
	DIALOGUE_DURATION = 1.2
}

enum DisplayType {SPEECH_BUBBLE, FULLSCREEN}

static func parse_csv(dialogue_file: String, npc: NPC) -> ConversationTree:
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	var keys := file.get_csv_line()

	# Lambda helpers
	var get_key = func(csv_line: PackedStringArray, key: String) -> String:
		var idx = keys.find(key)
		if idx == -1:
			assert(false, "Error when parsing dialogue, cannot find key " + key)
		return csv_line[idx]

	var conversation_tree = ConversationTree.new()
	while not file.eof_reached():
		var line := file.get_csv_line()

		# create responses
		var responses: Array[Response] = []
		for response_num in range(1, MAX_RESPONSES + 1):
			var text = get_key.call(line, "R%s Text" % response_num)
			if text.is_empty():
				break
			
			var spawn_condition = get_key.call(line, "R%s Spawn Condition" % response_num)
			var is_impulsive_reponse = to_bool(get_key.call(line, "R%s Is Impulsive Response" % response_num))
			var res_variable_to_set = get_key.call(line, "R%s Variable To Set" % response_num)
			var res_variable_value = to_bool(get_key.call(line, "R%s Variable Value" % response_num))
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

			init_global_variable(spawn_condition)
			init_global_variable(res_variable_to_set)

			var response = Response.new(
				text,
				spawn_condition,
				res_expected_condition_value,
				is_impulsive_reponse,
				res_variable_to_set,
				res_variable_value,
				res_next_branch_id
			)
			responses.append(response)

		# create branch
		var branch_id = get_key.call(line, "Branch")
		if branch_id.is_empty():
			# Ignore empty branches, allows for header labels
			continue
		
		var dialogue_line = BBCodeParser.parse(get_key.call(line, "Dialogue Text"))
		safety_check_dialogue_commands(dialogue_line, npc)
		var npc_name = get_key.call(line, "Name")
		var display_type = to_display_type(get_key.call(line, "Display Type"))
		var variable_to_set = get_key.call(line, "Variable To Set")
		var variable_value = to_bool(get_key.call(line, "Variable Value"))
		var next_branch_id = get_key.call(line, "Next Branch")
		var condition = get_key.call(line, "Condition")
		var conditional_next_branch_id = get_key.call(line, "Conditional Next Branch")

		# Determine condition prefixing
		var expected_condition_value: bool
		if condition != "":
			if condition[0] == CONDITION_INVERSE_PREFIX:
				expected_condition_value = false
				condition = condition.substr(1)
			else:
				expected_condition_value = true
		
		# Center fullscreen dialogue
		if display_type == DisplayType.FULLSCREEN and not dialogue_line.is_empty():
			dialogue_line = "[center]" + dialogue_line + "[/center]"
		
		init_global_variable(variable_to_set)
		init_global_variable(condition)

		conversation_tree.branches[branch_id] = ConversationBranch.new(
			branch_id,
			dialogue_line,
			npc_name,
			display_type,
			variable_to_set,
			variable_value,
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
		"0", "FALSE": return false
		"1", "TRUE": return true
		"": return false
		_:
			assert(false, "Error when parsing dialogue, tried to convert " + string + " to bool, expected '0' or '1'")

static func to_display_type(string: String):
	match string:
		"", "Speech Bubble":
			return DisplayType.SPEECH_BUBBLE
		"Fullscreen":
			return DisplayType.FULLSCREEN
		_:
			assert(false, "Error when parsing dialogue, received \"" + string + "\" in display type column, expected an empty string, \"Speech Bubble\" or \"Fullscreen\"")

static func error_if_empty(string: String, error_msg: String):
	if string.is_empty():
		assert(false, error_msg)
	else:
		return string

static func init_global_variable(variable_name: String):
	if variable_name.is_empty():
		return
	if not Global.dialogue_conditions.has(variable_name):
		Global.dialogue_conditions[variable_name] = false

static func safety_check_dialogue_commands(string: String, npc: NPC):
	var command_search = RegEx.new()
	command_search.compile("{(.+?)}")
	for command_match: RegExMatch in command_search.search_all(string):
		var command_line = command_match.strings[1].split(" ")
		var command = command_line[0]
		match command:
			DialogueUI.DIALOGUE_COMMANDS.PAUSE, DialogueUI.DIALOGUE_COMMANDS.SPEED:
				assert(
					command_line.size() == 2,
					"Issue when parsing dialogue, expected dialogue command \"" + command + "\" to have 1 argument, instead received " + str(command_line.size() - 1)
				)
				assert(
					command_line[1].is_valid_float(),
					"Issue when parsing dialogue, the argument \"" + command_line[1] + "\" for command \"" + command + "\" cannot be converted to a float"
				)
			DialogueUI.DIALOGUE_COMMANDS.SHAKE:
				if command_line.size() == 1:
					continue
				for arg in command_line.slice(1):
					var arg_match = match_shake_args(arg)
					assert(
						arg_match != null,
						"Issue when parsing dialogue, received argument \"" + arg + "\" for shake command, arguments must be in the format \"amount=#\" or \"duration=#\" where # is any valid float"
					)
			DialogueUI.DIALOGUE_COMMANDS.ANIMATION:
				assert(
					npc.npc_sprite is AnimatedSprite2D,
					"Issue when parsing dialogue, trying to call animation dialogue command on npc that doesn't have an AnimatedSprite2D"
				)
				assert(
					npc.npc_sprite.sprite_frames.has_animation(command_line[1]),
					"Issue when parsing dialogue, dialogue command trying to play animation \"" + command_line[1] + "\", which is not in the AnimatedSprite2D of " + npc.name
				)
			_:
				assert(false, "Issue when parsing dialogue, invalid dialogue command or BBCode macro \"" + command + "\"")

static func match_shake_args(arg: String) -> RegExMatch:
	var arg_search = RegEx.new()
	arg_search.compile("(amount|duration)=(\\d*\\.?\\d+)")
	return arg_search.search(arg)

static func strip_dialogue_commands(string: String) -> String:
	var regex = RegEx.new()
	regex.compile("{.+?}")
	return regex.sub(string, "", true)

# static func set_variable_safety_checks(variable_to_set: String, variable_value: String):
# 	if not variable_to_set.is_empty() and not Global.dialogue_conditions.has(variable_to_set):
# 		assert(false, "Issue when parsing dialogue, planning to set variable \"" + variable_to_set + "\" which does not exist in Global.dialogue_conditions")
# 	if not variable_to_set.is_empty() and variable_value.is_empty():
# 		assert(false, "Error when parsing dialogue, the variable to set \"" + variable_to_set + "\" has no associated value")

# static func get_variable_safety_checks(variable_to_get: String):
# 	if not variable_to_get.is_empty() and not Global.dialogue_conditions.has(variable_to_get):
# 		assert(false, "Issue when parsing dialogue, planning to get variable \"" + variable_to_get + "\" which does not exist in Global.dialogue_conditions")
