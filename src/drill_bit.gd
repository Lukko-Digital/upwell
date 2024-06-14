extends RigidBody2D
class_name DrillBit

enum Substance {ROCK, DIRT, AIR, NONE}

var substance = Substance.NONE

func _ready():
    linear_damp_mode = DampMode.DAMP_MODE_REPLACE
    # lock_rotation = true

func _on_enter_rock(_body: Node2D):
    if substance == Substance.NONE:
        substance = Substance.ROCK
        set_deferred("freeze", true)
        # set_axis_velocity(Vector2.ZERO)
        # freeze = true

func _on_enter_dirt(_body: Node2D):
    if substance == Substance.NONE:
        substance = Substance.DIRT
        gravity_scale = 0.0
        linear_damp = 10.0

func _on_exit_dirt(_body: Node2D):
    if substance == Substance.DIRT:
        substance = Substance.AIR
        gravity_scale = 1.0
        linear_damp = 0.0