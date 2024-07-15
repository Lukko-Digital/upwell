extends Button
class_name ResponseButton

@onready var despawn_timer: Timer = $DespawnTimer

var despawn_time: float
var response_obj: Response

signal response_selected(response_obj: Response)

## Call this before instantiating object
# [display_time]: the time it takes for the current dialogue line to be displayed
func start(display_time: float, response_obj_: Response):
	response_obj = response_obj_
	text = response_obj.response_text
	despawn_time = response_obj.despawn_time * display_time

func _ready() -> void:
	despawn_timer.start(despawn_time)

func _on_despawn_timer_timeout() -> void:
	get_parent().remove_child(self)
	queue_free()

func _on_pressed():
	response_selected.emit(response_obj)