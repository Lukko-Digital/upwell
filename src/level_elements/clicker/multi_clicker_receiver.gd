extends Node2D
class_name MultiClickerReceiver

## The time you have to insert the reset of the clickers after the first is inserted
@export var countdown_time: float
@export var countdown_bar: ProgressBar
@export var countdown_timer: Timer
@export var receivers: Array[ClickerHolder]

var completed: bool = false

func _ready() -> void:
    for receiver in receivers:
        receiver.clicker_state_changed.connect(_receiver_state_changed)
    countdown_timer.wait_time = countdown_time
    countdown_bar.max_value = countdown_time
    countdown_bar.value = 0

func _process(_delta: float) -> void:
    if !countdown_timer.is_stopped():
        countdown_bar.value = countdown_time - countdown_timer.time_left

func _receiver_state_changed(_receiver: ClickerHolder, has_clicker: bool):
    if has_clicker:
        # Clicker inserted
        if receivers.all(func(rec): return rec.has_clicker):
            # If all clickers are in
            countdown_bar.modulate = Color.GREEN
            countdown_bar.value = countdown_time
            countdown_timer.stop()
            completed = true
        elif countdown_timer.is_stopped():
            countdown_timer.start()

    else:
        # Clicker removed
        if completed:
            countdown_bar.modulate = Color.WHITE
            countdown_bar.value = 0
            completed = false

func _on_countdown_timer_timeout() -> void:
    for receiver in receivers:
        receiver.drop_clicker(get_parent())
    countdown_bar.modulate = Color.RED
    await get_tree().create_timer(1).timeout
    countdown_bar.modulate = Color.WHITE
    countdown_bar.value = 0