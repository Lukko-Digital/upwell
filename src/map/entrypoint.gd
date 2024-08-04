extends MapLocation
class_name Entrypoint

@export_range(0, 10) var entry_number: int = 0

@onready var map_level: MapLevel = get_parent()
@onready var hovered_sprite: Sprite2D = $EntrypointSelected
@onready var unhovered_sprite: Sprite2D = $EntrypointUnselected

var selected: bool = false

var teleporting = false # for changing the map player location when the pod is called

func _ready() -> void:
	super()
	player.select_destination.connect(select)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			player.location_selected(self)

func pod_called() -> void:
	teleporting = true

func select(location: Entrypoint) -> void:
	if location == self:
		selected = true
		hovered()
	else:
		selected = false
		unhovered()

func hovered() -> void:
	hovered_sprite.visible = true
	unhovered_sprite.visible = false

func unhovered() -> void:
	hovered_sprite.visible = false
	unhovered_sprite.visible = true

func _on_area_entered(area: Area2D):
	if area.get_name() == "PlayerBody":
		if teleporting:
			teleporting = false
		else:
			map_level.visit(entry_number)
			player.destination = self

func _on_area_exited(_area: Area2D):
	player.check_entrypoint_exited()

func _on_mouse_entered() -> void:
	if not Engine.is_editor_hint():
		hovered()

func _on_mouse_exited() -> void:
	if not Engine.is_editor_hint():
		if not selected:
			unhovered()
