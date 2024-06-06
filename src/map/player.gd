extends Sprite2D

var resources = {
	"fuel": 10.0,
	"drill": 10.0,
	"water": 10.0
}

func move_to(pipe: Pipe):
	position = pipe.position

	for resource in pipe.cost:
		resources[resource] -= pipe.cost[resource]

	for resource in pipe.resources:
		resources[resource] += pipe.resources[resource]
		print(resource, ": ", resources[resource])
