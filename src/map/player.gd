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
		pipe.resources[resource] = 0
		pipe.resources_text = "harvested"
		resources[resource] = min(resources[resource], 10.0)
		print(resource, ": ", resources[resource])