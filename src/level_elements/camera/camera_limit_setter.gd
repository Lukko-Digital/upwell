@tool
extends Area2D
class_name CameraLimitSetter

func _ready() -> void:
    set_collision_mask_value(1, false)
    set_collision_layer_value(1, false)

func set_disabled(value: bool):
    for child in get_children():
        if child is CollisionShape2D or child is CollisionPolygon2D:
            child.disabled = value
    print(name)