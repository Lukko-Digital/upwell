@tool
extends Area2D
class_name MapLevel

@export var level: PackedScene
@export var locked: bool = false

@export var label: Label

@export var name_text: String:
	set(value):
		name_text = value
		label.text = value
		
@export var sprite_scale: float
		

@onready var player: MapPlayer = owner.get_node("MapPlayer")
@onready var game: Game = get_tree().get_current_scene()
@onready var gravity_area = $Gravity

func _ready() -> void:
	if not Engine.is_editor_hint():
		hide()

func _process(_delta):
	if not Engine.is_editor_hint():
		gravity_area.visible = Global.pod_has_clicker
	$Sprite2D.scale = Vector2(1 * sprite_scale, 1 * sprite_scale)
	$Label.position.y = sprite_scale * 50
	$CollisionShape2D.scale = Vector2(1 * sprite_scale, 1 * sprite_scale)

func _on_mouse_entered() -> void:
	if not Engine.is_editor_hint():
		player.location_hovered(self)

func _on_mouse_exited() -> void:
	if not Engine.is_editor_hint():
		player.location_unhovered(self)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			player.location_selected(self)

func _on_area_entered(area: Area2D):
	if area.get_name() == "PlayerBody":
		modulate = Color.DIM_GRAY
		player.destination = self
		game.change_level(level)
