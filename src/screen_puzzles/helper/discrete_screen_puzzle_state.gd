extends Resource
class_name DiscreteScreenPuzzleState

var in_ag: bool
var orbiting: bool
## Array of Area2D
var overlapping_areas: Array
var previous_point: Vector2

func _init(
    in_ag_: bool,
    orbiting_: bool,
    overlapping_areas_: Array,
    previous_point_: Vector2
) -> void:
    in_ag = in_ag_
    orbiting = orbiting_
    overlapping_areas = overlapping_areas_
    previous_point = previous_point_