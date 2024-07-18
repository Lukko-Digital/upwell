extends Node2D


# @export var child: Sprite2D
@export var pod: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		for secondChild in child.get_children():
			secondChild.position -= pod.position
	pass # Replace with function body.

func _process(_delta):
	# child.global_position = pod.global_position
	pass
