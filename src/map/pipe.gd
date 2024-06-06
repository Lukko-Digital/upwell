extends ColorRect
class_name Pipe

@onready var hovered_box = $Hovered
@onready var hitbox = $Hitbox
@onready var info_tag = $InfoTag

@onready var info_unknown = $InfoTag/Unknown
@onready var pipe_info = $InfoTag/PipeInfo
@onready var too_far = $InfoTag/TooFar

@onready var player = get_parent().get_parent().get_node("Player")

signal clicked(pipe)

var player_can_see = false
var player_can_move = false

const info_template = "kind: %s \ncost: %.1f fuel, %.1f drill \nresources: %s"

var cost = {"fuel" = 0, "drill" = 0}
var resources = {"fuel" = 0, "drill" = 0, "water" = 0}
var attributes: PipeAttributes

const ATTRIBUTES_LIST: Array[PipeAttributes] = [
	preload ("res://src/map/pipe_types/lore.tres"),
	preload ("res://src/map/pipe_types/plants.tres"),
	preload ("res://src/map/pipe_types/rocks.tres"),
	preload ("res://src/map/pipe_types/village.tres"),
]

func _ready():
	attributes = ATTRIBUTES_LIST[randi() % ATTRIBUTES_LIST.size()]
	for resource in attributes.resources:
		resources[resource] = attributes.resources[resource]

	hide()
	info_tag.hide()
	pipe_info.hide()

	for pipe: Pipe in get_parent().get_children():
		pipe.clicked.connect(update_cost)

	update_cost()

func _on_mouse_entered():
	hovered_box.show()
	info_tag.show()

func _on_mouse_exited():
	hovered_box.hide()
	info_tag.hide()

func can_move() -> bool:
	for resource in cost:
		if player.resources[resource] < cost[resource]:
			return false
	return player_can_move and player.position.distance_squared_to(position) > 1

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT and
			event.pressed and
			can_move()
		):
			player.move_to(self)
			clicked.emit(self)

func _on_hitbox_area_entered(area):
	match area.name:
		"MovementRadius":
			player_can_move = true
			too_far.hide()
		"VisionRadius":
			player_can_see = true
			pipe_info.show()
			info_unknown.hide()
			show()

func _on_hitbox_area_exited(area):
	match area.name:
		"MovementRadius":
			player_can_move = false
			too_far.show()
		"VisionRadius":
			player_can_see = false
			pipe_info.hide()
			info_unknown.show()

func update_cost(pipe: Pipe=null):
	cost["fuel"] = position.distance_to(player.position) / 200
	cost["drill"] = position.distance_to(player.position) / 200
	pipe_info.text = info_template % [attributes.resource_name, cost["fuel"],cost["drill"],attributes.get_info()]