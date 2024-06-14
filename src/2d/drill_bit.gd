extends RigidBody2D
class_name DrillBit

var has_been_stuck = false

func _on_area_2d_body_entered(body: Node2D):
    if not has_been_stuck:
        set_deferred("freeze", true)
        has_been_stuck = true