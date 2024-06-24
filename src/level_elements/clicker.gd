extends Interactable
class_name Clicker

@onready var body: RigidBody2D = get_parent()

func _process(_delta):
	# Interact label always appears right side up
	rotation = -body.rotation

func interact(player: Player):
	if player.has_clicker:
		return
	player.has_clicker = true
	body.queue_free()