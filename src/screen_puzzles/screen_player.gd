@tool
extends Node2D
class_name ScreenPlayer

const STARTING_POWER = 200
const SPACING: float = 10

var targeted_folder: ScreenCore = null

@onready var trajectory_line: Line2D = %TrajectoryLine
@onready var line_area: TrajectoryLineArea = %LineCollisionArea
@onready var new_action_line: Line2D = %NewActionLine

func _ready() -> void:
	spawn_collision_segments(STARTING_POWER)
	update_main_line()

func update_main_line():
	targeted_folder = update_trajectory(trajectory_line)
	update_collision_segments()

func update_new_action_line():
	update_trajectory(new_action_line, true)

func clear_new_action_line():
	new_action_line.clear_points()

## Returns the folder that was hit, if no folder was hit, returns null
func update_trajectory(line: Line2D, detect_unplaced: bool=false) -> ScreenCore:
	line.clear_points()

	var dir: Vector2 = Vector2.UP
	var in_ag: ScreenAG = null
	var orbiting: bool = false

	var world_physics := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_areas = true
	query.collision_mask = 32 # Layer 6
	query.position = global_position

	var power = STARTING_POWER
	var used_power_ups = []
	var total_line_power = power

	while power > 0:
		var overlapping = world_physics.intersect_point(query)
		
		in_ag = null
		for collision in overlapping:
			var area = collision.collider
			if area is ScreenAG:
				in_ag = area

		for collision in overlapping:
			var area = collision.collider
			if area is ScreenButton:
				if not in_ag:
					continue
				if not (detect_unplaced or area.placed):
					continue
				match area.type:
					ScreenButton.ButtonTypes.ORBIT:
						orbiting = true
					ScreenButton.ButtonTypes.UNORBIT:
						orbiting = false
					ScreenButton.ButtonTypes.BOOST:
						orbiting = false
						dir = -query.position.direction_to(in_ag.global_position)
			if area is ScreenHazard:
				return null
			if area is ScreenCore:
				return area

			if area is ScreenPowerUp:
				if area not in used_power_ups:
					used_power_ups.append(area)
					power += area.power
					total_line_power += area.power
					var child_diff = total_line_power - line_area.get_child_count()
					if child_diff > 0:
						spawn_collision_segments(child_diff)

		if orbiting and in_ag:
			var vec_to_ag = in_ag.global_position - query.position
			var angle = acos(SPACING / (2 * vec_to_ag.length()))
			var orbit_dir = sign(vec_to_ag.angle_to(dir))
			dir = vec_to_ag.normalized().rotated(angle * orbit_dir)
		
		line.add_point(query.position - global_position)
		query.position += dir * SPACING
		power -= 1
	return null

func spawn_collision_segments(num_segments: int):
	for _i in range(num_segments):
		var collision = CollisionShape2D.new()
		var segment = SegmentShape2D.new()
		segment.a = Vector2.ZERO
		segment.b = Vector2.ZERO
		collision.shape = segment
		line_area.add_child(collision)

func update_collision_segments():
	var points = Array(trajectory_line.points)
	var point_a: Vector2 = points.pop_front()
	var point_b: Vector2
	for collision: CollisionShape2D in line_area.get_children():
		if points.is_empty():
			point_a = Vector2.ZERO
			point_b = Vector2.ZERO
		else:
			point_b = point_a
			point_a = points.pop_front()
		collision.shape.a = point_a
		collision.shape.b = point_b
