extends Node2D
class_name EmptyPod

@export var is_entrace: bool = false

@onready var hider: Node2D = $Hider

func handle_empty():
    hider.handle_empty()

func _ready():
    if not is_entrace:
        hider.handle_empty()