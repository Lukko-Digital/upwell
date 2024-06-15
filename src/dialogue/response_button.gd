extends Button
class_name ResponseButton

@onready var despawn_timer: Timer = $DespawnTimer
@onready var despawn_bar: ProgressBar = $DespawnBar

var despawn_time: float

func start(despawn_time_: float):
	despawn_time = despawn_time_

func _ready() -> void:
	despawn_timer.start(despawn_time)
	despawn_bar.max_value = despawn_time
	despawn_bar.value = 0

func _process(_delta: float) -> void:
	despawn_bar.value = despawn_timer.wait_time - despawn_timer.time_left

func _on_despawn_timer_timeout() -> void:
	get_parent().remove_child(self)
	queue_free()
