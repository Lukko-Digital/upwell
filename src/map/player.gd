extends Sprite2D

@onready var resource_bars = $UI/ResourceBars

var current_pipe: Pipe = null

var resources = {
	"fuel": 100.0,
	"drill": 100.0,
}

func move_to(pipe: Pipe):
	current_pipe = pipe
	position = current_pipe.position
	
	for resource in pipe.cost:
		resources[resource] -= current_pipe.cost[resource]
		print(resource, resources[resource])

	current_pipe.visited = true
