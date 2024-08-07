extends CanvasLayer
class_name MapUI

const UNDISCOVERED_TEXT = "[b]UNDISCOVERED[/b]\n\n"

@onready var map_player: MapPlayer = get_parent()
@onready var log_label: RichTextLabel = %LogLabel

func _ready() -> void:
    map_player.select_destination.connect(_on_select_destination)
    Global.set_dialogue_variable("MET_FRAUD", true)
    Global.set_dialogue_variable("VISITED_RUINS", true)
    
func _on_select_destination(location: Entrypoint):
    if location == null:
        return
    var level: MapLevel = location.get_parent()
    var text = ""
    var num_undiscovered = 0
    for key in level.log_dict:
        if Global.dialogue_conditions[key]:
            text += level.log_dict[key]
        else:
            num_undiscovered += 1
    text += UNDISCOVERED_TEXT.repeat(num_undiscovered)
    log_label.text = text

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