extends CanvasLayer
class_name DialogueUI

const TEXT_SPEED = 0.04

@onready var label: Label = $SpeechBubble/Label
@onready var duration_bar: ProgressBar = $SpeechBubble/DurationBar
# Timer for the duration of the text on the screen, set by duration variable of conversation branches
@onready var duration_timer: Timer = $DurationTimer
# Timer for animating text display, value set to TEXT_SPEED
@onready var display_timer: Timer = $DisplayTimer
@onready var response_box: VBoxContainer = $ResponseBox
@onready var response_button_scene = preload ("res://src/dialogue/response_button.tscn")

var default_branch = "A1"

var current_conversation: Conversation
var display_in_progress: bool = false
var response_button_queue := {}
var next_branch: String

signal dialogue_finished

func _ready():
	hide()
	clear_responses()

func _process(_delta):
	animate_duration_bar()

func start_dialogue(npc: NPC):
	show()
	var conversation_id: String = Global.npc_conversation_state[npc.name]
	current_conversation = npc.conversations[conversation_id]
	play_branch(default_branch)

func play_branch(branch_id: String):
	clear_responses()
	var branch: ConversationBranch = current_conversation.branches[branch_id]
	var display_time = branch.dialogue_line.length() * (TEXT_SPEED + get_process_delta_time())

	label.text = branch.dialogue_line
	duration_timer.start(display_time * branch.duration)
	next_branch = branch.next_branch_id
	for response in branch.responses:
		spawn_reponse(response, display_time)
	animate_display()

func animate_display():
	label.visible_characters = 0
	while label.visible_characters < len(label.text):
		label.visible_characters += 1
		display_timer.start(TEXT_SPEED)
		await display_timer.timeout

func spawn_reponse(response: Response, display_time: float):
	var instance: ResponseButton = response_button_scene.instantiate()
	response_button_queue[instance] = null
	await get_tree().create_timer(response.spawn_time * display_time).timeout

	if not response_button_queue.has(instance):
		return
	
	response_button_queue.erase(instance)
	instance.text = response.response_text
	var despawn_time_seconds = (
		response.despawn_time * display_time if response.despawn_time != INF
		else duration_timer.time_left
	)
	instance.start(despawn_time_seconds, response.next_branch_id)
	response_box.add_child(instance)
	instance.response_selected.connect(_response_button_pressed)

func clear_responses():
	response_button_queue.clear()
	for button in response_box.get_children():
		response_box.remove_child(button)
		button.queue_free()

func animate_duration_bar():
	duration_bar.max_value = duration_timer.wait_time
	duration_bar.value = duration_timer.wait_time - duration_timer.time_left

func exit_dialogue():
	if current_conversation.next_conversation_id:
		Global.npc_conversation_state[current_conversation.npc_name] = current_conversation.next_conversation_id
	hide()
	dialogue_finished.emit()

func _response_button_pressed(branch_id: String):
	if branch_id == "EXIT":
		exit_dialogue()
	else:
		play_branch(branch_id)

func _on_duration_timer_timeout():
	if next_branch == "EXIT":
		exit_dialogue()
	else:
		play_branch(next_branch)
