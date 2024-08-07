extends CanvasLayer
class_name MapUI

const UNDISCOVERED_TEXT = "[b]UNDISCOVERED[/b]\n\n"

const FUEL_LAUNCH_TEXT = {
    LOW = "Fuel consumption is low",
    MID = "Fuel consumption is moderate",
    TOO_FAR = "[color=red][b]WARNING. Destination exceeds fuel range."
}

const TRAJECTORY_LAUNCH_TEXT = {
    CLEAR = "Trajectory is unblocked.",
    BLOCKED = "[color=red][b]WARNING. Trajectory obstructed."
}

@export var fuel_launch_label: RichTextLabel
@export var trajectory_launch_label: RichTextLabel
@export var log_label: RichTextLabel

@onready var map_player: MapPlayer = get_parent()

func _ready() -> void:
    Global.set_dialogue_variable("MET_FRAUD", true)
    Global.set_dialogue_variable("VISITED_RUINS", true)

## [fuel_consumption] is a percentage of fuel that is needed to reach the
## destination. 0.5 means half of the fuel will be used, a number above one
## means there is not enough fuel to reach the destination
func update_travel_info(location: Entrypoint, path_clear: bool, fuel_consumption: float):
    if fuel_consumption < 0.5:
        fuel_launch_label.text = FUEL_LAUNCH_TEXT.LOW
    elif fuel_consumption < 1:
        fuel_launch_label.text = FUEL_LAUNCH_TEXT.MID
    else:
        fuel_launch_label.text = FUEL_LAUNCH_TEXT.TOO_FAR

    if path_clear:
        trajectory_launch_label.text = TRAJECTORY_LAUNCH_TEXT.CLEAR
    else:
        trajectory_launch_label.text = TRAJECTORY_LAUNCH_TEXT.BLOCKED

    log_label.text = get_log_text(location)

func get_log_text(location: Entrypoint) -> String:
    var level: MapLevel = location.get_parent()
    var text = ""
    var num_undiscovered = 0
    for key in level.log_dict:
        if Global.dialogue_conditions[key]:
            text += level.log_dict[key]
        else:
            num_undiscovered += 1
    text += UNDISCOVERED_TEXT.repeat(num_undiscovered)
    return text

func _on_text_backer_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        # Consume mouse inputs to prevent zooming while scrolling the log
        get_viewport().set_input_as_handled()

## Josh code here

func _on_launch_button_pressed() -> void:
    pass # Replace with function body.

func _on_launch_button_mouse_entered() -> void:
    pass # Replace with function body.

func _on_launch_button_mouse_exited() -> void:
    pass # Replace with function body.