extends PathFollow2D
class_name OneButtonPathFollow

@export var speed: float = 400
@export var button: HolderButton
@export var line: Line2D

## +1 or -1, representing forward or backwards
var direction = 1

func _ready() -> void:
    loop = false
    for point in get_parent().curve.get_baked_points():
        line.add_point(point)

func _process(delta: float) -> void:
    if button.has_clicker:
        progress += speed * delta * direction
    match progress_ratio:
        0.0: direction = 1
        1.0: direction = -1