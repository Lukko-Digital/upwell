extends PathFollow2D
class_name TwoButtonPathFollow

@export var speed: float = 400
## Forward is the direction away from the first point in the path
@export var forward_button: HolderButton
## Backward is the direction towards the first point in the path
@export var backward_button: HolderButton
@export var line: Line2D

func _ready() -> void:
    loop = false
    for point in get_parent().curve.get_baked_points():
        line.add_point(point)

func _process(delta: float) -> void:
    var direction = 0
    if forward_button.has_clicker:
        direction += 1
    if backward_button.has_clicker:
        direction -= 1
    progress += speed * delta * direction