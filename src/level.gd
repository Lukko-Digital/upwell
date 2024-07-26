extends Node2D
class_name Level

@onready var clicker_scene: PackedScene = preload ("res://src/clicker/clicker.tscn")

func load_from_level_data():
	if not Global.level_save_state.has(scene_file_path):
		return

	for clicker_data: ClickerSaveData in Global.level_save_state[scene_file_path]:
		print(clicker_data.home_holder_path, clicker_data.location)
		var instance = clicker_scene.instantiate()
		instance.home_holder = get_node(clicker_data.home_holder_path)
		if clicker_data.location is NodePath:
			get_node(clicker_data.location).owned_clicker = instance
		elif clicker_data.location is Vector2:
			instance.set_deferred("position", clicker_data.location)
		add_child(instance)

func save_level_data():
	var clicker_saves: Array[ClickerSaveData] = []
	for clicker: ClickerBody in get_tree().get_nodes_in_group("Clickers"):
		var home_holder_path = get_path_to(clicker.home_holder)
		var location
		if clicker.holder_owned_by:
			location = get_path_to(clicker.holder_owned_by)
		else:
			location = clicker.position
		print(home_holder_path, location)
		clicker_saves.append(
			ClickerSaveData.new(
				home_holder_path,
				location
			)
		)
	Global.level_save_state[scene_file_path] = clicker_saves
