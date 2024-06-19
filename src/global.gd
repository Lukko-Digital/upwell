extends Node

var clicker_state = {}
var level_unlocks = {}

signal level_unlocked(level)

func unlock_level(level_name: String):
    level_unlocks[level_name] = true
    level_unlocked.emit(level_name)
    print(level_name)