extends Node2D
class_name MultiReceiver

var receivers: Array[ClickerHolder]

signal completion_state_changed(completed: bool)

var completed: bool:
    set(value):
        completion_state_changed.emit(value)
        completed = value

func _ready() -> void:
    for child in get_children():
        if child is ClickerHolder:
            receivers.append(child)
            child.clicker_state_changed.connect(_receiver_state_changed)

    if all_holders_have_clickers():
        on_completion()
    else:
        completed = false

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
