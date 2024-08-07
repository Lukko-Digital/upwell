extends Node
class_name LogFileParser

static func parse(file_path: String) -> Dictionary:
    var file = FileAccess.open(file_path, FileAccess.READ)
    var key = ""
    var log_dict = {}
    while not file.eof_reached():
        var line := file.get_line()
        if line.begins_with("!"):
            key = line.substr(1)
            log_dict[key] = ""
        elif key:
            log_dict[key] += line + "\n"
    return log_dict