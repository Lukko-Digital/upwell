@tool
extends PoweredObjected
## Allow a [CameraLimitSetter] to be powered on and off. By default, power on
## will enable the limit setter, and power off will disable it.
class_name PoweredLimitSetter

var limit_setter: CameraLimitSetter

func _ready() -> void:
    limit_setter = get_limit_setter()
    assert(limit_setter != null, name + " missing camera bound or camera track child.")
    super()

func power_on():
    limit_setter.set_disabled(false)

func power_off():
    limit_setter.set_disabled(true)

func get_limit_setter():
    for child in get_children():
        if child is CameraLimitSetter:
            return child
    return null

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = []

    if get_limit_setter() == null:
        warnings.append("Missing camera bound or camera track child.")

    return warnings