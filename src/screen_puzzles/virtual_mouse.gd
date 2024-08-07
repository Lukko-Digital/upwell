extends Sprite2D

func _ready() -> void:
    Global.camera_focus_changed.connect(_on_camera_focus_changed)

func _process(_delta):
    global_position = get_global_mouse_position() + Vector2(11, 11)

func _on_camera_focus_changed(focus: Node2D):
    if focus == null:
        hide()
    elif focus is ScreenInteractable:
        show()