extends Interactable
class_name NPC

@export_file("*.csv") var dialogue_file

var conversation_tree: ConversationTree

func _ready() -> void:
	super()
	conversation_tree = DialogueParser.parse_csv(dialogue_file, name)
	conversation_tree.print()

func interact(player: Player):
	player.start_dialogue(self)