extends Node

## NULL is not a level but allows receivers to indicate that they do not unlock
## any level
enum LevelIDs {
    NULL,
    DAD,
    L0,
    L0A,
    L1,
    L2,
    L3,
    WIN,
}

var player_has_clicker = false
var clicker_state = {}
var level_unlocks = {}
var npc_conversation_state = {}

signal level_unlocked(level_name: LevelIDs)

func unlock_level(level_name: LevelIDs):
    level_unlocks[level_name] = true
    level_unlocked.emit(level_name)