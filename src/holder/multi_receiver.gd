extends Node2D
class_name MultiReceiver

@export var receivers: Array[ClickerHolder]

signal completion_state_changed(completed: bool)

var completed: bool = false:
    set(value):
        completion_state_changed.emit(value)
        completed = value

func _ready() -> void:
    for receiver in receivers:
        receiver.clicker_state_changed.connect(_receiver_state_changed)

func on_completion():
    completed = true

func _receiver_state_changed(_receiver: ClickerHolder, has_clicker: bool):
    if has_clicker:
        # Clicker inserted
        if receivers.all(func(rec): return rec.has_clicker()):
            # All clickers are in
            on_completion()
    else:
		# Clicker removed
        if completed:
            completed = false
