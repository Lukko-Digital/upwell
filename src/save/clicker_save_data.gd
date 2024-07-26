extends Resource
class_name ClickerSaveData

var home_holder_path: String
## Either a position or a path to a holder
var location: Variant

func _init(home_holder_path_: String, location_: Variant) -> void:
    home_holder_path = home_holder_path_
    location = location_