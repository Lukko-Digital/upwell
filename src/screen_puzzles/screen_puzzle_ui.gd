extends Control
class_name ScreenPuzzleUI

@export var screen_player: ScreenPlayer
@export var launch_result_label: RichTextLabel

const LAUNCH_TEXT = {
	SUCCESS = "[wave amp=150.0 freq=5.0 connected=1][color=green][center] LAUNCH SUCCESS [/center][/color][/wave]",
	FAIL = "[shake rate=20.0 level=30 connected=1][color=red][center] LAUNCH FAILED [/center][/color][/shake]",
}

func _ready() -> void:
	launch_result_label.hide()

func _on_launch_button_pressed() -> void:
	var folder_hit: ScreenCore = screen_player.update_tragectory()
	if folder_hit:
		folder_hit.visit()
		launch_result_label.text = LAUNCH_TEXT.SUCCESS
	else:
		launch_result_label.text = LAUNCH_TEXT.FAIL
	launch_result_label.show()
	await get_tree().create_timer(1).timeout
	launch_result_label.hide()
