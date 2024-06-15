extends Resource
class_name Conversation

# dict from String of branch ID to ConversationBranch
var branches: Dictionary = {}
var id: String

func _init(id_: String) -> void:
    id = id_