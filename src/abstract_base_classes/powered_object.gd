extends Node2D
class_name PoweredObjected

## The [ClickerHolder] that this object is powered by. This export or
## [param power_multi] should be left blank.
@export var power_holder: ClickerHolder = null
## The [TimedMultiReceiver] that this object is powered by. This export or
##  [param power_holder] should be left blank.
@export var power_multi: TimedMultiReceiver = null
## Default [code]false[/code]. This object is powered when the holder has a clicker.
## If [code]true[/code], this object will be powered when the holder doesn't have a clicker.
@export var negative_relationship: bool = false

func _ready() -> void:
    # Safety checks
    assert(
        power_holder != null or power_multi != null,
        "The PoweredObject " + name + " doesn't have a power_holder or a
        power_multi set. It should have one of the two."
    )
    assert(
        power_holder == null or power_multi == null,
        "The PoweredObject " + name + " has a power_holder and power_multi set.
        It should only have one of the two."
    )

    if power_holder:
        power_holder.clicker_state_changed.connect(_holder_state_changed)
        # Call function explicitly because the initial state change signal isn't
        # necessarily received
        handle_power(power_holder.has_clicker())
    if power_multi:
        power_multi.completion_state_changed.connect(_multi_state_changed)
        # Call function explicitly because the initial state change signal isn't
        # necessarily received
        handle_power(power_multi.completed)

func power_on():
    pass

func power_off():
    pass

func handle_power(provided_power: bool):
    ## Truth table
    ## provided_power | negative_relationship | power
    ## -------------------------------------------
    ## true           | true                  | false
    ## true           | false                 | true
    ## false          | true                  | true
    ## false          | false                 | false
    if provided_power != negative_relationship:
        power_on()
    else:
        power_off()

func _holder_state_changed(_holder: ClickerHolder, has_clicker: bool):
    handle_power(has_clicker)

func _multi_state_changed(completed: bool):
    handle_power(completed)