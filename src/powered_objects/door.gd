extends PoweredObjected
class_name Door

@export var animation_player: AnimationPlayer

func power_on():
    animation_player.play("open")

func power_off():
    animation_player.play("closed")