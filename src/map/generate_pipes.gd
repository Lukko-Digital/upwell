extends Node

signal done_generating

var pipe = preload ("res://src/map/pipe.tscn")

@export var angle_variance = PI / 6
@export var separation_angle = PI / 3
@export var roots = 5
@export var depth = 15
@export var distance_variance = 50
@export var child_distribution = [10, 6, 2, 1, 1]

var direction = Vector2.UP
var distance = 180

func _ready():
	var temp = []
	for i in range(child_distribution.size()):
		for j in range(child_distribution[i]):
			temp.append(i)
	child_distribution = temp

	for i in range(roots):
		var pipe_instance = pipe.instantiate()
		var offset = randi_range( - distance_variance, distance_variance)
		pipe_instance.position = direction * (distance + offset) / 1.5

		done_generating.connect(pipe_instance.connect_click_signal)

		add_child(pipe_instance)

		generate_tree(pipe_instance.position, direction, 0)

		direction = direction.rotated(2 * PI / roots)

	done_generating.emit()

func generate_tree(pos: Vector2, dir: Vector2, d: int):
	if d == depth:
		return
	
	var pipe_instance = pipe.instantiate()
	var offset = randi_range( - distance_variance, distance_variance)
	pipe_instance.position = pos + dir * (distance + offset)

	done_generating.connect(pipe_instance.connect_click_signal)

	add_child(pipe_instance)

	var num_children
	if d <= 1:
		num_children = 1
	else:
		num_children = child_distribution[randi() % child_distribution.size()]

	for i in range(num_children):
		var new_dir = dir.rotated(separation_angle * (i - num_children / 2.0) + randf_range( - angle_variance, angle_variance))
		generate_tree(pipe_instance.position, new_dir, d + 1)
