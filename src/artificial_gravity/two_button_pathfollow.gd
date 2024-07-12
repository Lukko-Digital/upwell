extends ButtonControlledPathFollow
class_name TwoButtonPathFollow

## Forward is the direction away from the first point in the path
@export var forward_button: HolderButton
## Backward is the direction towards the first point in the path
@export var backward_button: HolderButton

func handle_movenent(delta):
    var direction = 0
    if forward_button.has_clicker:
        direction += 1
    if backward_button.has_clicker:
        direction -= 1
    progress += speed * delta * direction