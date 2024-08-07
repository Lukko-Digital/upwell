@tool
extends CanvasLayer
## Moves all child nodes to be the same global position as parent node
class_name UtilityCanvas

## By default only moves children on ready, if true, continuously checks for
## movement in process
@export var updates_in_process: bool = false

@onready var parent = get_parent()

var last_parent_pos: Vector2

func _ready() -> void:
    layer = 128
    move_children()

func _process(_delta: float) -> void:
    if Engine.is_editor_hint() or updates_in_process:
        if parent.global_position != last_parent_pos:
            move_children()

func move_children():
    last_parent_pos = parent.global_position
    for child in get_children():
        child.global_position = last_parent_pos