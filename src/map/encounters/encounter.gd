extends Resource
class_name Encounter

@export var prereq = {}
@export var text = ""
@export var cost = {}
@export var reward = {}
@export var next_encounters: Array[Encounter] = []