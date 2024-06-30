extends Node

var player_has_clicker = false

var drill_heat: float = 0
const MEDIUM_DRILL_HEAT: float = 25

var clicker_state = {}
var level_unlocks = {}
var npc_conversation_state = {}

signal level_unlocked(level_name)

func unlock_level(level_name: String):
    level_unlocks[level_name] = true
    level_unlocked.emit(level_name)