@tool
extends Control
class_name ScreenPuzzleUI

@export var folders_container: HBoxContainer
@export var main_text_label: RichTextLabel
@export var launch_result_label: RichTextLabel

@onready var screen_player: ScreenPlayer = %ScreenPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var backer_animation_player: AnimationPlayer = $TextBackerAnimationPlayer

const CHARS_PER_FRAME = 1
const LAUNCH_TEXT = {
	SUCCESS = "[wave amp=150.0 freq=5.0 connected=1][color=green][center] LAUNCH SUCCESS [/center][/color][/wave]",
	FAIL = "[shake rate=20.0 level=30 connected=1][color=red][center] LAUNCH FAILED [/center][/color][/shake]",
}

func _ready() -> void:
	for folder_button: FolderButton in folders_container.get_children():
		folder_button.folder_opened.connect(_on_folder_opened)

	launch_result_label.hide()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()

func animate_display():
	main_text_label.visible_characters = -1
	while main_text_label.visible_characters < main_text_label.text.length():
		main_text_label.visible_characters += CHARS_PER_FRAME
		await get_tree().process_frame

func _on_folder_opened(text: String):
	backer_animation_player.stop()
	backer_animation_player.play("backer_shine")
	await get_tree().create_timer(0.1).timeout
	main_text_label.text = text
	# animate_display() ## New animations make text readout unnecessary

func launch_success(folder: ScreenCore):
	if !folder.opened:
		print("!folder.opened")
		animation_player.stop()
		animation_player.play("launch_success")
	folder.opened = true
	folder.launch_success()
	screen_player.launch_success()

func launch_fail():
	animation_player.stop()
	animation_player.play("launch_fail")
	await get_tree().create_timer(0.001).timeout
	main_text_label.text = "[p] [/p][p] [/p][p] [/p][b][p][center]File not found at[/center][/p][p][center]specified destination[/center][/p][/b]"
	animate_display()

func _on_launch_button_pressed() -> void:
	var folder: ScreenCore = screen_player.targeted_folder
	if folder:
		launch_success(folder)
	else:
		launch_fail()

func _on_reset_button_pressed() -> void:
	# Reset all [ScreenButton] 
	get_tree().call_group("ScreenButtons", "go_home")

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []

	if %ScreenPlayer == null:
		warnings.append("ScreenPlayer needs to be set as unique node")

	return warnings
