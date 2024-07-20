@tool
extends GPUParticles2D

@export_range(0, 1) var minimum_scale: float = 0:
	set(value):
		process_material.scale_min = value
		minimum_scale = value
@export_range(0.01, 2) var maximum_scale: float = 0.05:
	set(value):
		process_material.scale_max = value
		maximum_scale = value

func _ready() -> void:
	add_to_group("Particles")
	process_material = process_material.duplicate()


func move_particles(new_position: Vector2):
	position = new_position
