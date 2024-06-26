extends Area2D
class_name MapLocation

@export var level: PackedScene
@export var locked_level_name: String

@export var location_type_script: GDScript = preload ("res://src/map/level.gd")

var location_type: LocationType = location_type_script.new()

func _ready() -> void:
	Global.level_unlocked.connect(level_unlocked)
	location_type.player = owner.get_node("MapPlayer")
	if locked_level_name:
		hide()

func _on_mouse_entered() -> void:
	location_type.location_hovered(self)

func _on_mouse_exited() -> void:
	location_type.location_unhovered(self)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			location_type.location_selected(self)

func level_unlocked(level_name: String):
	if level_name == locked_level_name:
		show()

func _on_area_entered(_area: Area2D):
	location_type.player_entered(self)
