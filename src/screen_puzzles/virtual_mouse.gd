extends Sprite2D

func _process(_delta):
    global_position = get_global_mouse_position() + Vector2(11, 11)