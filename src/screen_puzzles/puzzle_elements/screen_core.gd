extends FolderClickable
class_name ScreenCore

@export_multiline var text: String
@export var folder_button: FolderButton

## BBCode ready text
var parsed_text: String

func _ready() -> void:
	group = "ScreenCores"
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
	pass