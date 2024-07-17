extends CanvasLayer
class_name DialogueUI

const TEXT_SPEED = 0.03

@export var dialogue_label: RichTextLabel
@export var name_label: RichTextLabel
# Timer for the duration of the text on the screen, set by duration variable of conversation branches
@export var duration_timer: Timer
# Timer for animating text display, value set to TEXT_SPEED
@export var display_timer: Timer
@export var response_box: VBoxContainer

@onready var response_button_scene = preload ("res://src/dialogue/response_button.tscn")

var current_conversation: ConversationTree
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
	name_label.text = current_conversation.npc_name
	play_branch(DialogueParser.START_BRANCH_TAG)

func play_branch(branch_id: String):
	if branch_id == DialogueParser.END_TAG:
		exit_dialogue()
		return

	clear_responses()
	var branch: ConversationBranch = current_conversation.branches[branch_id]
	# Set dialogue text
	dialogue_label.text = branch.dialogue_line
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
	animate_display()

func animate_display():
	dialogue_label.visible_characters = 0
	while dialogue_label.visible_characters < len(dialogue_label.text):
		dialogue_label.visible_characters += 1
		display_timer.start(TEXT_SPEED)
		await display_timer.timeout

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
