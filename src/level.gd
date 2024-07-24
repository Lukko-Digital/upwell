extends Node2D
class_name Level

func set_position_with_canvaslayers(pos: Vector2):
    position = pos
    
    for child in get_children():
        if not child is CanvasLayer:
            continue
        for child2 in child.get_children():
            child2.position = pos