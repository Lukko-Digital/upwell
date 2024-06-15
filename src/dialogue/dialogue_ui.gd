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

var default_conversation = "NAR1"
var default_branch = "A1"

var current_conversation: Conversation
var display_in_progress: bool = false

func _ready():
	for button in response_box.get_children():
		response_box.remove_child(button)
		button.queue_free()

func _process(_delta):
	animate_duration_bar()

func start_dialogue(npc: Interactable):
	show()
	current_conversation = npc.conversations[default_conversation]
	play_branch(default_branch)

func play_branch(branch_id: String):
	var branch: ConversationBranch = current_conversation.branches[branch_id]
	var display_time = branch.dialogue_line.length() * TEXT_SPEED

	label.text = branch.dialogue_line
	duration_timer.start(display_time * branch.duration)
	for response in branch.responses:
		spawn_reponse(response, display_time)
	
	animate_display()

	await duration_timer.timeout

	var next = branch.next_branch_id
	if next == "EXIT":
		exit_dialogue()
	else:
		play_branch(next)

func animate_display():
	label.visible_characters = 0
	while label.visible_characters < len(label.text):
		label.visible_characters += 1
		display_timer.start(TEXT_SPEED)
		await display_timer.timeout

func spawn_reponse(response: Response, display_time: float):
	await get_tree().create_timer(response.spawn_time * display_time).timeout
	var instance: ResponseButton = response_button_scene.instantiate()
	instance.text = response.response_text
	var despawn_time_seconds = (
		response.despawn_time * display_time if response.despawn_time != INF
		else duration_timer.time_left
	)
	instance.start(despawn_time_seconds)
	response_box.add_child(instance)

func animate_duration_bar():
	duration_bar.max_value = duration_timer.wait_time
	duration_bar.value = duration_timer.wait_time - duration_timer.time_left

func exit_dialogue():
	pass
