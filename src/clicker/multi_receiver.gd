extends Node2D
class_name MultiReceiver

@export var unlocks_level: Global.LevelIDs = Global.LevelIDs.NULL
@export var receivers: Array[ClickerReceiver]

func _ready() -> void:
    for receiver in receivers:
        receiver.clicker_state_changed.connect(_receiver_state_changed)

func on_completion():
    if unlocks_level != Global.LevelIDs.NULL:
        Global.unlock_level(unlocks_level)

func _receiver_state_changed(_receiver: ClickerHolder, has_clicker: bool):
    if receivers.all(func(rec): return rec.has_clicker):
        # All clickers are in
        on_completion()