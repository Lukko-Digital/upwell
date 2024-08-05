@tool
extends MarginContainer
class_name SpeechBubbleContainer

const MAX_TEXT_WIDTH = 2500
## Somewhat arbitrary number, determined by just tweaking the value until speech
## bubbble lines up with nodule, will need change as the scale of various
## elements change
const NODULE_OFFSET = -9
## The percentage split of how the container is positioned to the nodule.
## 0.3 means 30% of the container will be to one side of the nodule, and 70%
## will be to the other side of the nodule.
const X_POSITION_PERCENTAGE = 0.4

@export var text_container: MarginContainer
@export var dialogue_label: RichTextLabel

@onready var text_margin = text_container.get_theme_constant("margin_left") + text_container.get_theme_constant("margin_right")

## This value is equal to [X_POSITION_PERCENTAGE] if the player is to the right,
## or equal to 1 - [X_POSITION_PERCENTAGE] if the player is to the left
var current_position_percentage: float
var last_seen_text: String

func _process(_delta: float) -> void:
	position.x = -size.x * scale.x * current_position_percentage
	position.y = -size.y * scale.y + NODULE_OFFSET
	size.y = 0
	if dialogue_label.text != last_seen_text:
		set_containter_width()
		last_seen_text = dialogue_label.text

func get_text_size(max_width: int) -> Vector2:
	return dialogue_label.get_theme_font("normal_font").get_multiline_string_size(
		dialogue_label.get_parsed_text(),
		HORIZONTAL_ALIGNMENT_LEFT,
		max_width,
		dialogue_label.get_theme_font_size("normal_font_size")
	)

func set_containter_width():
	## Add some extra padding to account for bold text, each bold character
	## adds about 1 pixel
	const PADDING = 30

	var text_size = get_text_size(-1)
	var target_line_count = ceil(text_size.x / float(MAX_TEXT_WIDTH))

	## Makes sure that short lines don't wrap even if [b] makes them larger than expected width
	if target_line_count < 2: dialogue_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	else: dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	var width = int(text_size.x)
	var smallest_viable_width: int
	var line_count = 1
	while line_count <= target_line_count and width > dialogue_label.custom_minimum_size.x:
		smallest_viable_width = width
		width -= 20
		line_count = get_text_size(width).y / text_size.y
	
	size.x = smallest_viable_width + text_margin + PADDING

## [dir_to_npc], either 1 or -1, if the npc is to the right or left,
## respectively, of the player
func orient_towards_player(dir_to_npc):
	if dir_to_npc == -1.0:
		# NPC on the left, player on the right
		current_position_percentage = X_POSITION_PERCENTAGE
	else:
		current_position_percentage = 1 - X_POSITION_PERCENTAGE