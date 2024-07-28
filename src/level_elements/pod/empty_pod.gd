extends Node2D
class_name EmptyPod

@export_range(0, 10) var entry_number: int = 0
@onready var hider: Node2D = $Hider

var is_entrace: bool = false

func handle_empty():
    hider.handle_empty()

func _ready() -> void:
    if not is_entrace:
        handle_empty()
