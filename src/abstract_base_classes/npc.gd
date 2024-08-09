extends Interactable
class_name NPC

@export var dialogue_loader: DialogueLoader

@export var faces_you_during_dialogue = false
## If the NPC sprite is normally facing to the left, check this box
@export var default_left_facing = false
## Only needs to be set if [faces_you_during_dialogue] is true.
## Can be a [Sprite2D] or [AnimatedSprite2D]
@export var npc_sprite: Node2D

@onready var speech_bubble: SpeechBubble = $SpeechBubble

var standing_locations: Array[DialogueStandLocation]

## Map from [String] of branch ID to [ConversationBranch]
var conversation_tree: Dictionary
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

	conversation_tree = DialogueParser.parse_csv(dialogue_loader, self)
	speech_bubble.hide()
	set_first_line()

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

	speech_bubble.bubble_container.orient_towards_player(sign(vec_to_player.x))
	speech_bubble.position.x = sign(vec_to_player.x) * abs(speech_bubble.position.x)
	speech_bubble.nodule.flip_h = player_on_right

func reset():
	speech_bubble.hide()
	if npc_sprite is AnimatedSprite2D:
		npc_sprite.play(default_animation)

## Called on ready. Sets the npc's speech bubble label to the first line of
## dialogue that would be said. For an unknown reason, this fixes the lag spike
## that happens when first interacting with an npc.
func set_first_line(branch_id: String = DialogueParser.START_BRANCH_TAG):
	var branch: ConversationBranch = conversation_tree[branch_id]
	speech_bubble.dialogue_label.text = DialogueParser.strip_dialogue_commands(branch.dialogue_line)
	var next_branch = branch.next_branch_id
	# Check conditional branch advancement
	if branch.condition != "":
		if Global.dialogue_conditions[branch.condition] == branch.expected_condition_value:
			next_branch = branch.conditional_next_branch_id
	# Go through boolean algebra lines
	if branch.dialogue_line.is_empty():
		set_first_line(next_branch)