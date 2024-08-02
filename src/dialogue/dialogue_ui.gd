extends CanvasLayer
class_name DialogueUI

## Usages:
##
## {pause #} where # is pause duration in seconds
##
## {speed #} where # is a multiplier on speed (2 means twice as fast, 0.5 means
##	twice as slow)
##
## {shake} {shake amount=#} {shake lerp_speed=#} {shake amount=# lerp_speed=#}
## 	# for amount is max pixel offset, # for lerp_speed is the speed at which
## 	the shake lerps down to zero
##
## {animation [animation_name]} where [animation_name] is a string corresponding
##	to an animation on the NPC's AnimatedSprite2D
const DIALOGUE_COMMANDS = {
	PAUSE = "pause",
	SPEED = "speed",
	SHAKE = "shake",
	ANIMATION = "animation"
}
const SHAKE_DEFAULT = {
	AMOUNT = 50,
	LERP_SPEED = 10.0
}

const TEXT_SPEED = 0.035
## How long it will take for the next character to appear, in seconds
const END_CHARACTER_PAUSE = 0.6
const COMMA_PAUSE = 0.3

## Distance from nodule origin to npc origin
const SPEECH_BUBBLE_OFFSET = Vector2(-60, -110)

# Timer for animating text display, value set to TEXT_SPEED
@export var display_timer: Timer
@export var response_box: VBoxContainer
@export var fullscreen_display: FullscreenDialogue
@export var response_selector: ResponseButtonSelector

@onready var response_button_scene = preload("res://src/dialogue/response_button.tscn")
@onready var speech_bubble_scene = preload("res://src/dialogue/speech_bubble.tscn")

var active_dialogue_display: DialogueDisplay
var current_speech_bubble: SpeechBubble
var current_npc: NPC
var next_branch: String
var display_speed_coef = 1
## Boolean whether the player can hit [esc] to exit dialogue or not
var locked_in_dialogue: bool

signal display_animation_finished
signal dialogue_finished

func _ready():
	hide()
	clear_responses()

## [dir_to_npc], either 1 or -1, if the npc is to the right or left,
## respectively, of the player
func start_dialogue(npc: NPC, dir_to_npc: float):
	fullscreen_display.hide()
	show()
	current_npc = npc
	
	# Spawn speech bubble
	var instance = speech_bubble_scene.instantiate()
	instance.init(
		npc.nodule.position,
		npc.nodule.flip_h,
		dir_to_npc
	)
	current_speech_bubble = instance
	npc.add_child(instance)

	play_branch(DialogueParser.START_BRANCH_TAG)

func play_branch(branch_id: String):
	if branch_id == DialogueParser.END_TAG:
		exit_dialogue()
		return

	clear_responses()
	var branch: ConversationBranch = current_npc.conversation_tree.branches[branch_id]
	# Set [locked_in_dialogue]
	locked_in_dialogue = branch.locked_in_dialogue
	# Determine if speech bubble or fullscreen should be used
	match branch.display_type:
		DialogueParser.DisplayType.SPEECH_BUBBLE:
			active_dialogue_display = current_speech_bubble
			fullscreen_display.hide()
		DialogueParser.DisplayType.FULLSCREEN:
			active_dialogue_display = fullscreen_display
			fullscreen_display.show()
	# Set dialogue text
	active_dialogue_display.dialogue_label.text = DialogueParser.strip_dialogue_commands(branch.dialogue_line)
	# If there is a name, set it
	if branch.npc_name != "":
		active_dialogue_display.name_label.text = "[b]" + branch.npc_name + "[/b]"
	# If there is a variable to set, set it
	if branch.variable_to_set != "":
		Global.dialogue_conditions[branch.variable_to_set] = branch.variable_value
	# Set next branch
	next_branch = branch.next_branch_id
	# Check conditional branch advancement
	if branch.condition != "":
		if Global.dialogue_conditions[branch.condition] == branch.expected_condition_value:
			next_branch = branch.conditional_next_branch_id

	if branch.dialogue_line.is_empty():
		# If there is no dialogue text, immediately play next branch, in the case of boolean algebra lines
		play_branch(next_branch)
		return

	# Spawn impulsive responses
	for response in branch.responses:
		if response.is_impulsive_reponse:
			spawn_reponse(response)

	animate_display(branch.dialogue_line)
	await display_animation_finished

	clear_responses()
	
	if branch.responses.is_empty():
		# Advance if no responses
		play_branch(next_branch)
	else:
		# Spawn normal responses
		for response in branch.responses:
			if not response.is_impulsive_reponse:
				spawn_reponse(response)

func animate_display(dialogue_line: String):
	## Just the characters that will be seen, no bbcode
	active_dialogue_display.dialogue_label.visible_characters = 0
	var command_text = BBCodeParser.strip_bbcode(dialogue_line)
	var bbcode_text = DialogueParser.strip_dialogue_commands(dialogue_line)
	var idx = 0
	while idx < command_text.length():
		# Exit if there is no current_npc. This will happen when the player
		# exits dialogue prematurely via [esc].
		if current_npc == null:
			return

		# Cancel this instance of display animation if text is mismatched
		# This will happen when an impulsive response is pressed
		if active_dialogue_display.dialogue_label.text != bbcode_text:
			return

		var new_char = command_text[idx]
		
		if new_char == "{":
			# Dialogue command
			idx = handle_dialogue_command(command_text, idx)
		else:
			var wait_time = calculate_wait_time(new_char, command_text, idx)
			display_timer.start(wait_time)
			# Show new character
			active_dialogue_display.dialogue_label.visible_characters += 1
			idx += 1
			
		if not display_timer.is_stopped():
			await display_timer.timeout
	display_animation_finished.emit()

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
			var amount: float = SHAKE_DEFAULT.AMOUNT
			var lerp_speed: float = SHAKE_DEFAULT.LERP_SPEED
			if command_line.size() != 1:
				# Override default shake values
				for arg in command_line.slice(1):
					var arg_match = DialogueParser.match_shake_args(arg)
					var param = arg_match.strings[1]
					var value = arg_match.strings[2].to_float()
					match param:
						"amount":
							amount = value
						"lerp_speed":
							lerp_speed = value
			Global.main_camera.start_shake()
			Global.main_camera.set_shake_and_lerp_to_zero(amount, lerp_speed)
		DIALOGUE_COMMANDS.ANIMATION:
			current_npc.npc_sprite.play(command_line[1])
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

func spawn_reponse(response: Response):
	if response.spawn_condition != "":
		if Global.dialogue_conditions[response.spawn_condition] != response.expected_condition_value:
			# If spawn condition is not satisfied, exit
			return
	var instance: ResponseButton = response_button_scene.instantiate()
	instance.start(response)
	instance.response_selected.connect(_response_button_pressed)
	response_box.add_child(instance)
	if response_box.get_child_count() == 1:
		# Focus the first button
		instance.grab_focus()
		# Wait for container to position button
		await get_tree().process_frame
		if is_instance_valid(instance):
			response_selector.show()
			response_selector.teleport_to_button(instance)

func clear_responses():
	response_selector.hide()
	for button in response_box.get_children():
		response_box.remove_child(button)
		button.queue_free()

func exit_dialogue():
	current_npc.reset()
	current_npc = null
	hide()

	# Despawn speech bubble
	if current_speech_bubble:
		current_speech_bubble.get_parent().remove_child(current_speech_bubble)
		current_speech_bubble.queue_free()
		current_speech_bubble = null

	dialogue_finished.emit()

func _response_button_pressed(response: Response):
	# Set variables
	if response.variable_to_set != "":
		Global.dialogue_conditions[response.variable_to_set] = response.variable_value
	# Next branch
	play_branch(response.next_branch_id)
