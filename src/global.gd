extends Node

var player_has_clicker = false
var clicker_state = {}
var level_unlocks = {}

signal level_unlocked(level_name)

func unlock_level(level_name: String):
    level_unlocks[level_name] = true
    level_unlocked.emit(level_name)