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
##
## {fade_off} after this command is seen, tail will be advanced with head,
## making the fade not visible
##
## {fade_on} tail is set to its usual trailing state
const DIALOGUE_COMMANDS = {
	PAUSE = "pause",
	SPEED = "speed",
	SHAKE = "shake",
	ANIMATION = "animation",
	FADE_OFF = "fade_off",
	FADE_ON = "fade_on"
}
const SHAKE_DEFAULT = {
	AMOUNT = 50,
	LERP_SPEED = 10.0
}

## Default time it takes to advance fade_head
const TEXT_SPEED = 0.035
## The time delay between advancing fade_head to advancing fade_tail
const TAIL_DELAY = 0.07
const FADE_MAX_LENGTH = 5
## How long it will take for the next character to appear, in seconds
const END_CHARACTER_PAUSE = 0.6
const COMMA_PAUSE = 0.3

## Distance from nodule origin to npc origin
const SPEECH_BUBBLE_OFFSET = Vector2(-60, -110)

# Timer for animating text display, value set to TEXT_SPEED
@export var display_timer: Timer
@export var tail_timer: Timer
@export var response_box: VBoxContainer
@export var fullscreen_display: FullscreenDialogue
@export var response_selector: ResponseButtonSelector

@onready var response_button_scene = preload("res://src/dialogue/response_button.tscn")
@onready var speech_bubble_scene = preload("res://src/dialogue/speech_bubble.tscn")

@onready var player: Player = get_parent()

# ------------- Current Interaction -------------
var active_dialogue_display: DialogueDisplay
var current_npc: NPC
## Used to track and kill zombie [animate_display] instances
var interaction_timestamp: int
var next_branch: String

# ------------- Display Variables -------------
var display_speed_coef: float = 1
var fade_head: int = 0:
	set(value):
		fade_head = value
		# If exceeding max length, pull tail along
		if fade_head - fade_tail > FADE_MAX_LENGTH:
			fade_tail += 1
		# If fade is disabled, set tail to head
		if fade_disabled:
			fade_tail = fade_head

var fade_tail: int = 0:
	set(value):
		# Don't allow tail to exceed head
		fade_tail = min(value, fade_head)

var fade_disabled: bool = false
## Used to speed up tail when head reaches the end
var all_characters_visible: bool = false

## Boolean whether the player can hit [esc] to exit dialogue or not
var locked_in_dialogue: bool

signal display_animation_finished
signal dialogue_finished

## ------------------------------- CORE -------------------------------

func _ready():
	hide()
	clear_responses()
	tail_timer.timeout.connect(_on_tail_timer_timeout)

func _process(_delta: float) -> void:
	update_fade()
	if fade_tail < fade_head - 1 and tail_timer.is_stopped():
		var wait_time = TAIL_DELAY if not all_characters_visible else TEXT_SPEED
		tail_timer.start(wait_time)

	## Fix camera shake in fullscreen
	offset = player.camera.offset

func _on_tail_timer_timeout():
	fade_tail += 1

## ------------------------------ ENTER/EXIT ------------------------------

## [dir_to_npc], either 1 or -1, if the npc is to the right or left,
## respectively, of the player
func start_dialogue(npc: NPC):
	fullscreen_display.hide()
	show()
	current_npc = npc
	interaction_timestamp = Time.get_ticks_msec()

	play_branch(DialogueParser.START_BRANCH_TAG)

func exit_dialogue():
	current_npc.reset()
	current_npc = null
	interaction_timestamp = 0
	hide()
	dialogue_finished.emit()

## ------------------------------ DIALOGUE LOGIC ------------------------------

func play_branch(branch_id: String):
	if branch_id == DialogueParser.END_TAG:
		exit_dialogue()
		return

	clear_responses()
	var branch: ConversationBranch = current_npc.conversation_tree[branch_id]
	# Set [locked_in_dialogue]
	locked_in_dialogue = branch.locked_in_dialogue
	# Determine if speech bubble or fullscreen should be used
	match branch.display_type:
		DialogueParser.DisplayType.SPEECH_BUBBLE:
			active_dialogue_display = current_npc.speech_bubble
			fullscreen_display.hide()
		DialogueParser.DisplayType.FULLSCREEN:
			active_dialogue_display = fullscreen_display
			fullscreen_display.show()
	# Set dialogue text
	active_dialogue_display.dialogue_label.text = DialogueParser.strip_dialogue_commands(branch.dialogue_line)
	# Hide the display if there is no dialogue text. This will happen in
	# scripted scenes, such as when the NPC pauses for the player to walk
	# up to them
	if active_dialogue_display.dialogue_label.text.is_empty():
		active_dialogue_display.hide()
	else:
		active_dialogue_display.show()

	# If there is a name, set it
	if branch.npc_name != "":
		active_dialogue_display.name_label.text = "[b]" + branch.npc_name + "[/b]"
	# If there is a variable to set, set it
	if branch.variable_to_set != "":
		Global.set_dialogue_variable(branch.variable_to_set, branch.variable_value)
	# Set next branch
	next_branch = branch.next_branch_id
	# Check conditional branch advancement
	if branch.condition != "":
		if Global.dialogue_conditions[branch.condition] == branch.expected_condition_value:
			next_branch = branch.conditional_next_branch_id

	# If there is no dialogue text, immediately play next branch, in the case of boolean algebra lines
	if branch.dialogue_line.is_empty():
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

## ---------------------------- DISPLAY ANIMATION ----------------------------

func update_fade():
	if not active_dialogue_display:
		return
	active_dialogue_display.dialogue_label.parse_bbcode(
		"[fade start=%s length=%s]" % [str(fade_tail), str(fade_head - fade_tail)] + active_dialogue_display.dialogue_label.text + "[/fade]"
	)

func animate_display(dialogue_line: String):
	var init_timestamp = interaction_timestamp
	
	all_characters_visible = false
	# Reset head and tail
	fade_head = 0
	fade_tail = 0

	## Just the characters that will be seen, no bbcode
	var command_text = BBCodeParser.strip_bbcode(dialogue_line)
	var bbcode_text = DialogueParser.strip_dialogue_commands(dialogue_line)
	## Current idx of the character of the command_text that animate display
	## is looking at
	var idx = 0
	while idx < command_text.length():
		# Exit if the interaction timestamp changed from what it was when this
		# function was instantiated. This will happen when the player exits
		# dialogue prematurely via [esc]. This also covers the case of the
		# player exiting dialogue during a {pause} and re-entering with the
		# same npc on the same first line.
		if init_timestamp != interaction_timestamp:
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
			idx += 1
			fade_head += 1
		
		if not display_timer.is_stopped():
			await display_timer.timeout
	display_animation_finished.emit()
	all_characters_visible = true

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
		DIALOGUE_COMMANDS.FADE_OFF:
			fade_disabled = true
		DIALOGUE_COMMANDS.FADE_ON:
			fade_disabled = false
	return re_match.get_end()

func calculate_wait_time(new_char: String, command_text: String, idx: int) -> float:
	var next_char = ""
	if idx + 1 < command_text.length():
		next_char = command_text[idx + 1]
	match new_char:
		".":
			# Don't slow down "..." as much
			if next_char == ".":
				return COMMA_PAUSE / 2
			else:
				return END_CHARACTER_PAUSE
		"!", "?":
			return END_CHARACTER_PAUSE
		",":
			return COMMA_PAUSE
		_:
			return TEXT_SPEED * display_speed_coef

## ------------------------------- RESPONSES -------------------------------

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

## ------------------------------- SIGNALS -------------------------------

func _response_button_pressed(response: Response):
	# Set variables
	if response.variable_to_set != "":
		Global.set_dialogue_variable(response.variable_to_set, response.variable_value)
	# Next branch
	play_branch(response.next_branch_id)