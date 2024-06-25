extends Interactable
class_name Clicker

@onready var body: RigidBody2D = get_parent()

func _ready() -> void:
	super()
	area_entered.connect(_on_area_entered)

func _process(_delta):
	# Interact label always appears right side up
	rotation = -body.rotation

func interact(player: Player):
	if player.has_clicker:
		return
	player.has_clicker = true
	body.queue_free()

func interact_condition(player: Player):
	return !player.has_clicker

func _on_area_entered(area: Area2D):
	if not area is ClickerHolder:
		return
	if area.has_clicker:
		return
	
	area.has_clicker = true
	area.enable_ags()
	body.queue_free()