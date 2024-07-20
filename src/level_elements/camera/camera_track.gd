@tool
extends CameraLimitSetter
class_name CameraTrack

func _ready() -> void:
    super()
    set_collision_layer_value(8, true)