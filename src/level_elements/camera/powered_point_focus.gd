@tool
extends PoweredObjected
## Allow a [CameraPointFocus] to be powered on and off. By default, power on
## will enable the point focus, and power off will disable it.
class_name PoweredPointFocus

var point_focus: CameraPointFocus

func _ready() -> void:
    point_focus = get_point_focus()
    assert(point_focus != null, name + " missing CameraPointFocus child.")
    super()

func power_on():
    point_focus.set_deferred("monitoring", true)

func power_off():
    point_focus.set_deferred("monitoring", false)

func get_point_focus():
    for child in get_children():
        if child is CameraPointFocus:
            return child
    return null

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = []

    if get_point_focus() == null:
        warnings.append("Missing CameraPointFocus child.")

    return warnings