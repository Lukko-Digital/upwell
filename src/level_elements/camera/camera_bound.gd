@tool
extends CameraLimitSetter
class_name CameraBound

func _ready() -> void:
    super()
    set_collision_layer_value(7, true)