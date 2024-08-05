@tool
extends Area2D
class_name CameraPointFocus

var marker: Marker2D

func _ready() -> void:
    set_collision_mask_value(1, false)
    set_collision_mask_value(2, true)
    set_collision_layer_value(1, false)

    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    marker = get_marker()
    assert(marker != null, name + " Missing focus point marker. Add a Marker2D.")

func _process(_delta: float) -> void:
    if Engine.is_editor_hint():
        update_configuration_warnings()

func get_marker():
    for child in get_children():
        if child is Marker2D:
            return child
    return null

func _on_body_entered(body: Node2D):
    if body is Player:
        Global.main_camera.set_focus(marker)

func _on_body_exited(body: Node2D):
    if body is Player:
        Global.main_camera.set_focus(null)

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = []

    if get_marker() == null:
        warnings.append("Missing focus point marker. Add a Marker2D.")

    return warnings