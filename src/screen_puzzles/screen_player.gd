@tool
extends Node2D
class_name ScreenPlayer

@export var STARTING_POWER: float = 1000
const SPACING: float = 2

@onready var line: Line2D = $Line2D

## Returns the folder that was hit, if no folder was hit, returns null
func update_tragectory() -> ScreenCore:
	line.clear_points()

	var dir: Vector2 = Vector2.UP
	var in_ag: ArtificialGravity = null
	var orbiting: bool = false

	var world_physics := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_areas = true
	query.collision_mask = 32
	query.position = global_position

	var power = STARTING_POWER
	var can_power_up = true

	while power > 0:
		var powered_up = false
		var overlapping = world_physics.intersect_point(query)
		
		in_ag = null
		for area in overlapping:
			if area.collider is ArtificialGravity:
				in_ag = area.collider

		for area in overlapping:
			if area.collider is ScreenButton:
				if in_ag and area.collider.type == ScreenButton.ButtonTypes.ORBIT:
					orbiting = true
				if area.collider.type == ScreenButton.ButtonTypes.UNORBIT:
					orbiting = false
				if in_ag and area.collider.type == ScreenButton.ButtonTypes.BOOST:
					orbiting = false
					dir = -query.position.direction_to(in_ag.global_position)
			if area.collider is ScreenHazard:
				return null
			if area.collider is ScreenCore:
				return area.collider

			if area.collider is ScreenPowerUp:
				if can_power_up:
					power += area.collider.power
					can_power_up = false
				powered_up = true
			
		if not powered_up:
			can_power_up = true

		if orbiting and in_ag:
			var orth = query.position.direction_to(in_ag.global_position).orthogonal().rotated(0.005)
			if dir.dot(orth) > 0:
				dir = orth
			else:
				dir = -orth

		line.add_point(query.position - global_position)
		query.position += dir * SPACING
		power -= 1
	return null

func _process(_delta: float) -> void:
	update_tragectory()
