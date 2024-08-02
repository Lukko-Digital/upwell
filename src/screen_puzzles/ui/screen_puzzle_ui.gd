@tool
extends Control
class_name ScreenPuzzleUI

@export var folders_container: HBoxContainer
@export var main_text_label: RichTextLabel
@export var launch_result_label: RichTextLabel

@onready var screen_player: ScreenPlayer = %ScreenPlayer

const CHARS_PER_FRAME = 5
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
	main_text_label.visible_characters = 0
	while main_text_label.visible_characters < main_text_label.text.length():
		main_text_label.visible_characters += CHARS_PER_FRAME
		await get_tree().process_frame

func _on_folder_opened(text: String):
	main_text_label.text = text
	animate_display()

func launch_success(folder: ScreenCore):
	folder.opened = true
	folder.launch_success()
	screen_player.launch_success()

	## REPLACE THIS WITH YOUR CODE
	launch_result_label.text = LAUNCH_TEXT.SUCCESS
	launch_result_label.show()
	await get_tree().create_timer(1).timeout
	launch_result_label.hide()
	## ---

func launch_fail():
	## REPLACE THIS WITH YOUR CODE
	launch_result_label.text = LAUNCH_TEXT.FAIL
	launch_result_label.show()
	await get_tree().create_timer(1).timeout
	launch_result_label.hide()
	## ---

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