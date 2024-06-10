extends Control

@onready var text = $Text
@onready var next_actions = $NextActions

var pipe_encounter = preload ("res://src/map/pipe_encounter.tscn")

func set_text(encounter: Encounter):
	await self.ready
	print(encounter.enter_text)
	text.text = encounter.enter_text

	for e in encounter.next_encounters:
		var button = Button.new()
		button.text = e.button_text
		button.pressed.connect(func(): get_parent().add_child(pipe_encounter.instantiate().set_text(e)))
		next_actions.add_child(button)