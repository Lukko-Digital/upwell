extends CanvasLayer
class_name DialogueUI

const TEXT_SPEED = 0.03

const DIALOGUE_COMMANDS = {
	PAUSE = "pause",
	SPEED = "speed",
	SHAKE = "shake",
}
const SHAKE_DEFAULT = {
	DURATION = 0.1,
	AMOUNT = 50
}
## How long it will take for the next character to appear, in seconds
const END_CHARACTER_PAUSE = 0.5
const COMMA_PAUSE = 0.15
## Distance from nodule origin to npc origin
const SPEECH_BUBBLE_OFFSET = Vector2( - 100, -130)

@export var dialogue_label: RichTextLabel
@export var name_label: RichTextLabel
@export var nodule: TextureRect
# Timer for the duration of the text on the screen, set by duration variable of conversation branches
@export var duration_timer: Timer
# Timer for animating text display, value set to TEXT_SPEED
@export var display_timer: Timer
@export var response_box: VBoxContainer

@onready var response_button_scene = preload ("res://src/dialogue/response_button.tscn")

var current_conversation: ConversationTree
var display_speed_coef = 1
var display_in_progress: bool = false
var response_button_queue := {}
var next_branch: String

signal dialogue_finished

func _ready():
	hide()
	clear_responses()

func start_dialogue(npc: NPC):
	show()
	current_conversation = npc.conversation_tree
	nodule.position = (npc.global_position - get_viewport().get_camera_2d().get_target_position()) / 2 + get_viewport().get_visible_rect().size / 2 + SPEECH_BUBBLE_OFFSET
	play_branch(DialogueParser.START_BRANCH_TAG)

func play_branch(branch_id: String):
	if branch_id == DialogueParser.END_TAG:
		exit_dialogue()
		return

	clear_responses()
	var branch: ConversationBranch = current_conversation.branches[branch_id]
	# Set dialogue text
	dialogue_label.text = DialogueParser.strip_dialogue_commands(branch.dialogue_line)
	# If there is a name, set it
	if branch.npc_name != "":
		name_label.text = "[b]" + branch.npc_name + "[/b]"
	# If there is a variable to set, set it
	if branch.variable_to_set != "":
		Global.dialogue_conditions[branch.variable_to_set] = branch.variable_value
	# Set next branch
	next_branch = branch.next_branch_id
	# Check conditional branch advancement
	if branch.condition != "":
		if Global.dialogue_conditions[branch.condition] == branch.expected_condition_value:
			next_branch = branch.conditional_next_branch_id

	# Handle Timer
	var display_time = branch.dialogue_line.length() * (TEXT_SPEED + get_process_delta_time())
	if branch.duration == 0:
		# If there is no duration, immediately play next branch, in the case of boolean algebra lines
		play_branch(next_branch)
		return
	elif branch.next_branch_id.is_empty():
		# If there is no next branch (i.e. when waiting for player response) the timer goes infinite
		duration_timer.start(INF)
	else:
		# Otherwise, start the timer normally
		duration_timer.start(display_time * branch.duration)
	# Spawn responses
	for response in branch.responses:
		spawn_reponse(response, display_time)
	animate_display(branch.dialogue_line)

func animate_display(dialogue_line: String):
	## Just the characters that will be seen, no bbcode
	dialogue_label.visible_characters = 0
	var command_text = BBCodeParser.strip_bbcode(dialogue_line)
	var idx = 0
	while idx < command_text.length():
		var new_char = command_text[idx]
		
		if new_char == "{":
			# Dialogue command
			idx = handle_dialogue_command(command_text, idx)
		else:
			var wait_time = calculate_wait_time(new_char, command_text, idx)
			display_timer.start(wait_time)
			# Show new character
			dialogue_label.visible_characters += 1
			idx += 1
			
		if not display_timer.is_stopped():
			await display_timer.timeout

## Returns the index of the end of the command, that should be jumped to
func handle_dialogue_command(command_text: String, idx: int) -> int:
	var regex = RegEx.new()
	regex.compile("{(.+?)}")
	var re_match: RegExMatch = regex.search(command_text, idx)
	var command_line = re_match.strings[1].split(" ")
	match command_line[0]:
		DIALOGUE_COMMANDS.PAUSE:
			display_timer.start(command_line[1].to_float())
		DIALOGUE_COMMANDS.SPEED:
			display_speed_coef = 1 / command_line[1].to_float()
		DIALOGUE_COMMANDS.SHAKE:
			var duration: float = SHAKE_DEFAULT.DURATION
			var amount: float = SHAKE_DEFAULT.AMOUNT
			if command_line.size() != 1:
				# Override default shake values
				for arg in command_line.slice(1):
					var arg_match = DialogueParser.match_shake_args(arg)
					var param = arg_match.strings[1]
					var value = arg_match.strings[2].to_float()
					match param:
						"amount":
							amount = value
						"duration":
							duration = value
			Global.camera_shake.emit(duration, amount)
	return re_match.get_end()

func calculate_wait_time(new_char: String, command_text: String, idx: int) -> float:
	var next_char = ""
	if idx + 1 < command_text.length():
		next_char = command_text[idx + 1]
	match new_char:
		".":
			# Don't slow down "..." as much
			if next_char == ".":
				return COMMA_PAUSE
			else:
				return END_CHARACTER_PAUSE
		"!", "?":
			return END_CHARACTER_PAUSE
		",":
			return COMMA_PAUSE
		_:
			return TEXT_SPEED * display_speed_coef

func spawn_reponse(response: Response, display_time: float):
	if response.spawn_condition != "":
		if Global.dialogue_conditions[response.spawn_condition] != response.expected_condition_value:
			# If spawn condition is not satisfied, exit
			return

	# Instantiate timer
	var instance: ResponseButton = response_button_scene.instantiate()
	response_button_queue[instance] = null
	await get_tree().create_timer(response.spawn_time * display_time).timeout

	if not response_button_queue.has(instance):
		# Will happen if buttons get despawned before they get the chance to spawn
		return
	
	# Remove from queue
	response_button_queue.erase(instance)
	# Start & Spawn
	instance.start(display_time, response)
	instance.response_selected.connect(_response_button_pressed)
	response_box.add_child(instance)

func clear_responses():
	response_button_queue.clear()
	for button in response_box.get_children():
		response_box.remove_child(button)
		button.queue_free()

func exit_dialogue():
	hide()
	dialogue_finished.emit()

func _response_button_pressed(response: Response):
	# Set variables
	if response.variable_to_set != "":
		Global.dialogue_conditions[response.variable_to_set] = response.variable_value
	# Next branch
	play_branch(response.next_branch_id)

func _on_duration_timer_timeout():
	play_branch(next_branch)
