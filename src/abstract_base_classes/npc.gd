extends Interactable
class_name NPC

@export_file("*.csv") var dialogue_file
@export var faces_you_during_dialogue = false
## If the NPC sprite is normally facing to the left, check this box
@export var default_left_facing = false
## Only needs to be set if [faces_you_during_dialogue] is true.
## Can be a [Sprite2D] or [AnimatedSprite2D]
@export var npc_sprite: Node2D

@onready var nodule: Sprite2D = $Nodule

var standing_locations: Array[DialogueStandLocation]

var conversation_tree: ConversationTree
## In the case that the npc's body isn't centered in the sprite
var default_sprite_offset: Vector2
## Only on [AnimatedSprite2D]
var default_animation: StringName

func _ready() -> void:
	super()
	# Get sprite offset
	if npc_sprite is Sprite2D or npc_sprite is AnimatedSprite2D:
		default_sprite_offset = npc_sprite.offset
		if npc_sprite is AnimatedSprite2D:
			default_animation = npc_sprite.animation
	# Get DialogueStandLocations
	for child in get_children():
		if not child is DialogueStandLocation:
			continue
		if child.disabled:
			continue
		standing_locations.append(child)

	conversation_tree = DialogueParser.parse_csv(dialogue_file, self)
	nodule.hide()

func interact(player: Player):
	interact_label.hide()
	player.init_npc_interaction(self)
	Global.main_camera.set_focus(self)

func face_player(player: Player):
	if not faces_you_during_dialogue:
		return

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

	var offset_dir = -1 if npc_sprite.flip_h else 1
	npc_sprite.offset = offset_dir * default_sprite_offset

	nodule.position.x = sign(vec_to_player.x) * abs(nodule.position.x)
	nodule.flip_h = player_on_right

func reset():
	if npc_sprite is AnimatedSprite2D:
		npc_sprite.play(default_animation)