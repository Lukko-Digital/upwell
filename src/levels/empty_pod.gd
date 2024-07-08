extends Node2D

func _ready():
	var new_pod = load("res://src/map/pod.tscn").instantiate()
	add_child(new_pod)
