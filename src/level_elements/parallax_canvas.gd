@tool
extends CanvasLayer
## Moves all child nodes to be the same global position as parent node
class_name ParallaxCanvas

@onready var parent = get_parent()

func _ready() -> void:
    follow_viewport_enabled = true
    move_children()

func _process(_delta: float) -> void:
    if Engine.is_editor_hint():
        move_children()

func move_children():
    for child in get_children():
        child.global_position = parent.global_position