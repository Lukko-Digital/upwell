extends FolderClickable
class_name FolderButton

## Set by the screen core
var paired_core: ScreenCore

signal folder_opened(text: String)

func _ready() -> void:
	group = "FolderButtons"
	super()

func open():
	# removed if highlighted, we want it to emit folder open on every launch, isnt emitting rn though HELP
	folder_opened.emit(paired_core.parsed_text)
	highlight()
	paired_core.highlight()