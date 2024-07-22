extends Interactable
class_name NPC

@export_file("*.csv") var dialogue_file

@export var npc_name: String

@onready var nodule: Sprite2D = $Nodule

var conversation_tree: ConversationTree

func _ready() -> void:
	super()
	assert(nodule != null, "NPC \"" + name + "\" has no nodule")
	nodule.hide()
	conversation_tree = DialogueParser.parse_csv(dialogue_file)

func interact(player: Player):
	player.start_dialogue(self)
	Global.set_camera_focus.emit(self)
