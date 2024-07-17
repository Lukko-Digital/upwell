extends Resource
class_name ConversationTree

# dict from String of branch ID to ConversationBranch
var npc_name: String
var branches: Dictionary = {}

func _init(npc_name_: String) -> void:
    npc_name = npc_name_

func print():
    for branch_id in branches:
        branches[branch_id].print()