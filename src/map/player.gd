extends Sprite2D

@onready var resource_bars = $ResourceBars
@onready var lore_label = $ResourceBars/lore

var resources = {
	"fuel": 10.0,
	"drill": 10.0,
	"water": 10.0
}

var lore: int = 0:
	set(value):
		lore = value
		lore_label.text = "%d" % value

func move_to(pipe: Pipe):
	position = pipe.position

	if pipe.attributes.name == "Lore" and pipe.resources_text != "harvested":
		lore += 1

	for resource in pipe.cost:
		resources[resource] -= pipe.cost[resource]

	for resource in pipe.resources:
		resources[resource] += pipe.resources[resource]

		pipe.resources[resource] = 0
		pipe.resources_text = "harvested"

		resources[resource] = min(resources[resource], 10.0)
		resource_bars.get_node(resource).value = resources[resource]

func _process(delta):
	resources["water"] -= delta * 0.5
	resource_bars.get_node("water").value = resources["water"]