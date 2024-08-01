extends DialogueDisplay
class_name SpeechBubble

@export var nodule: Sprite2D
@export var bubble_container: SpeechBubbleContainer

func init(
    position_: Vector2,
    nodule_flip: bool,
    dir_to_npc: float
):
    position = position_
    nodule.flip_h = nodule_flip
    bubble_container.orient_towards_player(dir_to_npc)