@tool
extends Area2D
class_name CameraLimitSetter

func _ready() -> void:
    set_collision_mask_value(1, false)
    set_collision_layer_value(1, false)