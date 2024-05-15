extends ColorRect
class_name Inventory_Icon

var item_name: String = ""
var item_count: int = 0
@onready var count_label: Label = $Label

func _get_drag_data(at_position):
	var data = {"index": get_parent().name.to_int()}

	var drag_texture = ColorRect.new()
	drag_texture.color = color
	drag_texture.set_size(size)

	var control = Control.new()
	control.add_child(drag_texture)
	drag_texture.set_position( - 0.5 * drag_texture.size)
	set_drag_preview(control)

	return data

func _can_drop_data(at_position, data):
	return true

func _drop_data(at_position, data):
	var i = get_parent().name.to_int()
	get_parent().get_parent().get_parent().swap(i, data["index"])
	
func update(data):
	if data == null:
		item_count = 0
		item_name = ""
		color = Color("ffffff00")
		count_label.text = ""
	else:
		color = data["texture"]
		item_count = data["count"]
		item_name = data["name"]
		count_label.text = str(item_count) if item_count > 1 else ""
