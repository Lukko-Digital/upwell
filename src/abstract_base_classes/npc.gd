extends Interactable
class_name NPC

@export_file("*.csv") var dialogue_file
@export var faces_you_during_dialogue = false
## If the NPC sprite is normally facing to the left, check this box
@export var default_left_facing = false
## Only needs to be set if [faces_you_during_dialogue] is true
@export var npc_sprite: Sprite2D

@onready var nodule: Sprite2D = $Nodule

var conversation_tree: ConversationTree

func _ready() -> void:
	super()
	nodule.hide()
	conversation_tree = DialogueParser.parse_csv(dialogue_file)

func interact(player: Player):
	if faces_you_during_dialogue:
		assert(npc_sprite != null, "You need to set the sprite export variable for NPC \"" + name + "\"")
		var vec_to_player = player.global_position - global_position
		var player_on_right = vec_to_player.x > 0
		## Truth table
		## player is on the right | default left facing | flip
		## -------------------------------------------
		## true           		  | true                | true
		## true           		  | false               | false
		## false         		  | true                | false
		## false          		  | false               | true
		npc_sprite.flip_h = (player_on_right == default_left_facing)
		nodule.position.x = sign(vec_to_player.x) * abs(nodule.position.x)
		nodule.flip_h = player_on_right

	player.start_dialogue(self)
	Global.set_camera_focus.emit(self)
