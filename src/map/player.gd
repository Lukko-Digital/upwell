extends Sprite2D

func _ready():
	for pipe: Pipe in get_parent().get_node("Pipes").get_children():
		pipe.clicked.connect(_pipe_selected)

func _pipe_selected(pipe: Pipe):
	position = pipe.position
