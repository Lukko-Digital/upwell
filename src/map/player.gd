extends Sprite2D

@onready var resource_bars = $UI/ResourceBars
@onready var encounter_container = $UI/EncounterContainer
@onready var encounters = $UI/EncounterContainer/ScrollContainer/Encounters

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

	encounter_container.show()

func leave_encounter():
	encounter_container.hide()
