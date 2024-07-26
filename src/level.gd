extends Node2D
class_name Level

@onready var clicker_scene: PackedScene = preload ("res://src/clicker/clicker.tscn")

func initialize_level():
    if Global.level_save_state.has(scene_file_path):
        load_from_level_data()
    else:
        get_tree().call_group("Holders", "init_starting_clicker")

func load_from_level_data():
    for clicker_data: ClickerSaveData in Global.level_save_state[scene_file_path]:
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
        var home_holder_path = clicker.home_holder.get_path()
        var location
        if clicker.holder_owned_by:
            location = clicker.holder_owned_by.get_path()
        else:
            location = clicker.position
        clicker_saves.append(
            ClickerSaveData.new(
                home_holder_path,
                location
            )
        )
    Global.level_save_state[scene_file_path] = clicker_saves
