extends Resource
class_name Conversation

# dict from String of branch ID to ConversationBranch
var branches: Dictionary = {}
var id: String

func _init(id_: String) -> void:
    id = id_

func print():
    print("conversation id: ", id)
    for branch_id in branches:
        branches[branch_id].print()