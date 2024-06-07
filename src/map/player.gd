extends Sprite2D

@onready var resource_bars = $ResourceBars
@onready var lore_label = $ResourceBars/lore

var current_pipe: Pipe = null

var resources = {
	"fuel": 100.0,
	"drill": 100.0,
	"water": 100.0
}

var lore: int = 0:
	set(value):
		lore = value
		lore_label.text = "%d" % value

func move_to(pipe: Pipe):
	current_pipe = pipe
	position = current_pipe.position
	
	for resource in pipe.cost:
		resources[resource] -= current_pipe.cost[resource]
		print(resource, resources[resource])

	update_resources()

	if current_pipe.attributes.name == "Lore" and not current_pipe.visited:
		current_pipe.color.a = 0.75
		lore += 1

	current_pipe.visited = true
	current_pipe.cost["drill"] = min(5, current_pipe.cost["drill"])

func _process(_delta):
	# resources["water"] -= delta * 2.5
	resource_bars.get_node("water").value = resources["water"]

func gather():
	if resources["drill"] < 5:
		return

	if not current_pipe.harvested:
		resources["drill"] -= 5

	for resource in current_pipe.resources:
		resources[resource] += current_pipe.resources[resource]

		current_pipe.resources[resource] = 0
		current_pipe.resources_text = "harvested"
		current_pipe.color.a = 0.5

	current_pipe.harvested = true

	update_resources()

func update_resources():
	for resource in current_pipe.resources:
		resources[resource] = min(resources[resource], 100.0)
		resource_bars.get_node(resource).value = resources[resource]