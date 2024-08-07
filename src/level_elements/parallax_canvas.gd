@tool
extends CanvasLayer
## Moves all child nodes to be the same global position as parent node
class_name ParallaxCanvas

## Sets the [follow_viewport_scale] equal to the value and sets [layer] and
## [name] according to the formula below. Value must be greater than 0.
## Converting to canvas layer number:
## When less than one, subtract 1 from the number and multiply by 100.
## e.g. 0.99 = -1, 0.9 = -10, 0.5 = -50
## When greater than one, multiply by 10. e.g. 1 = 10, 1.5 = 15, 2.1 = 21
@export var parallax_layer: float:
    set(value):
        if value < 1:
            layer = roundi(100.0 * (value - 1.0))
        elif value >= 1:
            layer = roundi(value * 10)
        
        follow_viewport_scale = value
        name = str(layer).replace(".", "_")
        parallax_layer = value
        update_configuration_warnings()

## By default only moves children on ready, if true, continuously checks for
## movement n process
@export var updates_in_process: bool = false

@onready var parent = get_parent()

var last_parent_pos: Vector2

func _ready() -> void:
    follow_viewport_enabled = true
    move_children()

func _process(_delta: float) -> void:
    if Engine.is_editor_hint() or updates_in_process:
        if parent.global_position != last_parent_pos:
            move_children()

func move_children():
    last_parent_pos = parent.global_position
    for child in get_children():
        child.global_position = last_parent_pos

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = []

    if parallax_layer <= 0:
        warnings.append("Parallax Layer must be greater than 0")

    return warnings