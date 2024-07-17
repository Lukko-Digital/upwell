extends ButtonControlledPathFollow
class_name OneButtonPathFollow

@export var button: ClickerHolder

## +1 or -1, representing forward or backwards
var direction = 1

func handle_movement(delta):
	if button.has_clicker:
		progress += speed * delta * direction
	match progress_ratio:
		0.0: direction = 1
		1.0: direction = -1