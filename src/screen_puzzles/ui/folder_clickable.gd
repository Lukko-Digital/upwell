extends TextureRect
class_name FolderClickable

@export var closed_texture: Texture2D
@export var open_texture: Texture2D

@onready var hover_glow: Sprite2D = $HoverGlow
@onready var selected_glow: Sprite2D = $SelectedGlow

## The folder is closed until opened by solving the puzzle
var opened = false:
    set(value):
        if value:
            texture = open_texture
            open()
        else:
            texture = closed_texture
        opened = value

var highlighed = false

var group: String

func _ready() -> void:
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    assert(not group.is_empty(), "Group name not set")
    add_to_group(group)

func open():
    pass

func highlight():
    get_tree().call_group(group, "dehighlight")
    highlighed = true
    selected_glow.show()

func dehighlight():
    highlighed = false
    selected_glow.hide()

func _on_gui_input(event: InputEvent) -> void:
	# When LMB pressed
    if (
        event is InputEventMouseButton and
        event.button_index == MOUSE_BUTTON_LEFT and
        event.pressed
    ):
        if not opened:
            return
        open()

func _on_mouse_entered() -> void:
    if not opened or highlighed:
        return
    hover_glow.show()

func _on_mouse_exited() -> void:
    hover_glow.hide()