extends Resource
class_name Conversation

# dict from String of branch ID to ConversationBranch
var npc_name: String
var branches: Dictionary = {}
var id: String
var next_conversation_id: String

func _init(npc_name_: String, id_: String, next_conversation_id_: String) -> void:
    npc_name = npc_name_
    id = id_
    next_conversation_id = next_conversation_id_

func print():
    print("conversation id: ", id)
    for branch_id in branches:
        branches[branch_id].print()