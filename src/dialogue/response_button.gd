extends TextureButton
class_name ResponseButton

@export var label: RichTextLabel

var response_obj: Response

signal response_selected(response_obj: Response)

## Call this before instantiating object
func start(response_obj_: Response):
	response_obj = response_obj_
	label.text = "[center]" + response_obj.response_text + "[/center]"

func _on_pressed():
	response_selected.emit(response_obj)