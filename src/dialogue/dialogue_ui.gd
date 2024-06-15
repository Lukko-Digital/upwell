extends CanvasLayer
class_name DialogueUI

const TEXT_SPEED = 0.04

@onready var label: Label = $SpeechBubble/Label
@onready var duration_bar: ProgressBar = $SpeechBubble/DurationBar
# Timer for the duration of the text on the screen, set by duration variable of conversation branches
@onready var duration_timer: Timer = $DurationTimer
# Timer for animating text display, value set to TEXT_SPEED
@onready var display_timer: Timer = $DisplayTimer

var default_conversation = "NAR1"
var default_branch = "A1"

var current_conversation: Conversation
var display_in_progress: bool = false

func _ready():
	pass

func _process(_delta):
	animate_duration_bar()

func start_dialogue(npc: Interactable):
	show()
	current_conversation = npc.conversations[default_conversation]
	play_branch(default_branch)

func play_branch(branch_id: String):
	var branch: ConversationBranch = current_conversation.branches[branch_id]
	label.text = branch.dialogue_line
	duration_timer.start(
		label.text.length() * TEXT_SPEED * branch.duration + get_process_delta_time()
	)
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

func animate_duration_bar():
	duration_bar.max_value = duration_timer.wait_time
	duration_bar.value = duration_timer.wait_time - duration_timer.time_left

func exit_dialogue():
	pass