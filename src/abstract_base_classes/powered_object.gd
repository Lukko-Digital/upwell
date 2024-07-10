extends Node2D
class_name PoweredObjected

@export var power_holder: ClickerHolder
## Default `false`. This object is powered when the holder has a clicker.
## If `true`, this object will be powered when the holder doesn't have a clicker.
@export var negative_relationship: bool = false

func _ready() -> void:
    power_holder.clicker_state_changed.connect(_holder_state_changed)
    ## Call function explicitly because the initial state change signal isn't
    ## necessarily received
    _holder_state_changed(power_holder, power_holder.has_clicker())

func power_on():
    pass

func power_off():
    pass

func _holder_state_changed(_holder: ClickerHolder, has_clicker: bool):
    ## Truth table
    ## has_clicker | negative_relationship | power
    ## -------------------------------------------
    ## true        | true                  | false
    ## true        | false                 | true
    ## false       | true                  | true
    ## false       | false                 | false
    if has_clicker != negative_relationship:
        power_on()
    else:
        power_off()