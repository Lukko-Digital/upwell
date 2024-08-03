@tool
extends FolderClickable
class_name ScreenCore

const GROUP_NAME = "ScreenCores"

@export_multiline var text: String
@export var folder_button: FolderButton:
	set(value):
		folder_button = value
		update_configuration_warnings()

@onready var animation_player: AnimationPlayer = %AnimationPlayer

## BBCode ready text
var parsed_text: String

func _ready() -> void:
	group = GROUP_NAME
	super()
	parsed_text = BBCodeParser.parse(text)
	folder_button.paired_core = self

func open() -> void:
	if highlighed:
		return
	# This will highlight the small folder
	folder_button.opened = true
	highlight()

func launch_success():
	animation_player.play("launch_success")

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []

	if folder_button == null:
		warnings.append("Missing folder button export")
	
	return warnings