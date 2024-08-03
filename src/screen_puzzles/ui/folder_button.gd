extends FolderClickable
class_name FolderButton

const GROUP_NAME = "FolderButtons"

## Set by the screen core
var paired_core: ScreenCore

signal folder_opened(text: String)

func _ready() -> void:
	group = GROUP_NAME
	super()

func open():
	if highlighed:
		return
	folder_opened.emit(paired_core.parsed_text)
	highlight()
	paired_core.highlight()