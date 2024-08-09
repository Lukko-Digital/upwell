@tool
extends Resource
class_name DialogueLoader

@export_global_file("*.csv") var csv_file:
    set(value):
        csv_file = value.get_file()
        take_over_path(resource_path.get_base_dir() + "/" + csv_file.get_basename() + ".tres")