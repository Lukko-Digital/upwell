extends Interactable
class_name NPC

@export_file("*.csv") var dialogue_file

@export var npc_name: String

var conversation_tree: ConversationTree

func _ready() -> void:
	super()
	conversation_tree = DialogueParser.parse_csv(dialogue_file, "[center]"+npc_name+"[/center]")

func interact(player: Player):
	player.start_dialogue(self)
