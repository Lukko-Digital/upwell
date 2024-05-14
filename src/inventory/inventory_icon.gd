extends TextureRect
class_name Inventory_Icon

var item: String = ""
var count: int = 0

func _get_drag_data(at_position):
	var data = {}

	var drag_texture = TextureRect.new()
	drag_texture.expand_mode = EXPAND_FIT_WIDTH
	drag_texture.texture = texture
	drag_texture.set_size(size)

	var control = Control.new()
	control.add_child(drag_texture)
	drag_texture.set_position( - 0.5 * drag_texture.size)
	set_drag_preview(control)

	data["node"] = self

	return data

func _can_drop_data(at_position, data):
	return true

func _drop_data(at_position, data):
	swap(data["node"])

func is_empty() -> bool:
	return count == 0 and item == ""

func swap(other: Inventory_Icon):
	var _item = item
	var _texture = texture
	var _count = count

	item = other.item
	texture = other.texture
	count = other.count

	other.item = _item
	other.texture = _texture
	other.count = _count
