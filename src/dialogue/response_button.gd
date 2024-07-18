extends Button
class_name ResponseButton

var response_obj: Response

signal response_selected(response_obj: Response)

## Call this before instantiating object
func start(response_obj_: Response):
	response_obj = response_obj_
	text = response_obj.response_text

func _on_pressed():
	response_selected.emit(response_obj)