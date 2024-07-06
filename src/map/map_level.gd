extends Area2D
class_name MapLevel

@export var level: PackedScene
@export var level_id: Global.LevelIDs
@export var locked: bool = false

@onready var player: MapPlayer = owner.get_node("MapPlayer")

@onready var game: Game = get_tree().get_current_scene()

func _ready() -> void:
	Global.level_unlocked.connect(level_unlocked)
	if locked:
		hide()

func _on_mouse_entered() -> void:
	player.location_hovered(self)

func _on_mouse_exited() -> void:
	player.location_unhovered(self)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			player.location_selected(self)

func level_unlocked(level_name: Global.LevelIDs):
	if locked and level_name == level_id:
		show()

func _on_area_entered(_area: Area2D):
	player.destination = self
	game.change_level(level)
