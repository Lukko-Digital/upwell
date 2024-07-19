extends PoweredObjected
class_name Door

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func power_on():
    animation_player.play("open")

func power_off():
    animation_player.play("closed")