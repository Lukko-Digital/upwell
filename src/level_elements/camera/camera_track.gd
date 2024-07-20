@tool
extends CameraLimitSetter
class_name CameraTrack

func _ready() -> void:
    super()
    set_collision_layer_value(8, true)
    if not Engine.is_editor_hint():
        generate_segments()

func _process(_delta: float) -> void:
    if Engine.is_editor_hint():
        update_configuration_warnings()

func generate_segments():
    var line = get_line()
    assert(line != null, name + " Missing track line. Add a Line2D.")
    line.hide()
    var points: PackedVector2Array = line.points
    for idx in range(points.size() - 1):
        var collision = CollisionShape2D.new()
        var segment = SegmentShape2D.new()
        segment.a = points[idx]
        segment.b = points[idx + 1]
        collision.shape = segment
        add_child(collision)

func get_line():
    for child in get_children():
        if child is Line2D:
            return child
    return null

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = []

    if get_line() == null:
        warnings.append("Missing track line. Add a Line2D.")

    return warnings