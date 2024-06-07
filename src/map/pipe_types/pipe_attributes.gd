extends Resource
class_name PipeAttributes

@export var name: String = ""
@export var resources = {"fuel": 0.0, "water": 0.0, "drill": 0.0}
@export var color: Color

@export var drill_cost: float = 1

func get_info() -> String:
    var info = ""
    for resource in resources:
        if resources[resource] > 0:
            info += "%.1f %s, " % [resources[resource],resource]
    return info