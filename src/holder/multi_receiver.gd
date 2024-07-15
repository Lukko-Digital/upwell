extends Node2D
class_name MultiReceiver

@export var receivers: Array[ClickerHolder]

signal completion_state_changed(completed: bool)

var completed: bool:
    set(value):
        completion_state_changed.emit(value)
        completed = value

func _ready() -> void:
    if all_holders_have_clickers():
        on_completion()
    else:
        completed = false
    
    for receiver in receivers:
        receiver.clicker_state_changed.connect(_receiver_state_changed)

func on_completion():
    completed = true

func all_holders_have_clickers():
    return receivers.all(func(rec): return rec.has_clicker())

func _receiver_state_changed(_receiver: ClickerHolder, has_clicker: bool):
    if has_clicker:
        # Clicker inserted
        if all_holders_have_clickers():
            # All clickers are in
            on_completion()
    else:
		# Clicker removed
        if completed:
            completed = false
