@tool
extends Node2D
class_name ScreenPlayer

const STARTING_POWER = 200
const SPACING: float = 10

signal main_line_updated()

@onready var trajectory_line: Line2D = %TrajectoryLine
@onready var line_area: TrajectoryLineArea = %LineCollisionArea
@onready var new_action_line: Line2D = %NewActionLine

## A map from all [Vector2] points in [trajectory_line] to [DiscreteScreenPuzzleState]
var point_states: Dictionary = {}
var targeted_folder: ScreenCore = null

func _ready() -> void:
	# Counter rotate lines so their coordinate axis is align with the global axis
	trajectory_line.rotation = -rotation
	new_action_line.rotation = -rotation
	spawn_collision_segments(STARTING_POWER)
	update_main_line()
	update_new_action_line()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		# Counter rotate lines so their coordinate axis is align with the global axis
		trajectory_line.rotation = -rotation
		new_action_line.rotation = -rotation
		update_trajectory(trajectory_line, false, true)

func update_main_line():
	targeted_folder = update_trajectory(trajectory_line, true, false)
	update_collision_segments()
	clear_new_action_line()
	main_line_updated.emit()

func update_new_action_line():
	update_trajectory(new_action_line, false, true)

func clear_new_action_line():
	new_action_line.clear_points()

func init_query() -> PhysicsPointQueryParameters2D:
	var query := PhysicsPointQueryParameters2D.new()
	query.collide_with_areas = true
	query.collision_mask = 32 # Layer 6
	query.position = global_position
	return query

func check_overlapping_ags(overlapping_areas: Array) -> ScreenAG:
	for area: Area2D in overlapping_areas:
		if area is ScreenAG:
			return area
	return null

## Returns the folder that was hit, if no folder was hit, returns null
func update_trajectory(
	line: Line2D,
	record_point_state: bool,
	detect_unplaced: bool
) -> ScreenCore:
	line.clear_points()
	if record_point_state:
		point_states.clear()

	var dir: Vector2 = Vector2.UP.rotated(rotation)
	# Power
	var power = STARTING_POWER
	var used_power_ups = []
	var total_line_power = power
	# AG
	var current_ag: ScreenAG = null
	var orbiting: bool = false
	# World query
	var world_physics := get_world_2d().direct_space_state
	var query = init_query()

	while power > 0:
		var query_result := world_physics.intersect_point(query)
		var overlapping_areas = query_result.map(func(collision): return collision.collider)
		
		# Check for colliding AGs first
		current_ag = check_overlapping_ags(overlapping_areas)

		# Resolve other colliding objects
		for area: Area2D in overlapping_areas:
			# Screen buttons
			if area is ScreenButton:
				if not current_ag:
					continue
				if not (detect_unplaced or area.placed):
					continue
				match area.type:
					ScreenButton.ButtonTypes.ORBIT:
						if orbiting:
							continue
						orbiting = true
					ScreenButton.ButtonTypes.UNORBIT:
						if not orbiting:
							continue
						orbiting = false
					ScreenButton.ButtonTypes.BOOST:
						if not orbiting:
							continue
						orbiting = false
						dir = -query.position.direction_to(current_ag.global_position)
			# Hazards
			if area is ScreenHazard:
				return null
			# Folders
			if area is ScreenCoreArea:
				return area.get_parent()
			# Power ups
			if area is ScreenPowerUp:
				# Only use each power up once
				if area in used_power_ups:
					continue
				used_power_ups.append(area)
				power += area.power
				total_line_power += area.power
				# Spawn more segments if needed
				var child_diff = total_line_power - line_area.get_child_count()
				if child_diff > 0:
					spawn_collision_segments(child_diff)

		# Handle orbit direction
		if orbiting and current_ag:
			var vec_to_ag = current_ag.global_position - query.position
			var angle = acos(SPACING / (2 * vec_to_ag.length()))
			var orbit_dir = sign(vec_to_ag.angle_to(dir))
			dir = vec_to_ag.normalized().rotated(angle * orbit_dir)
		
		# Update line and query
		var previous_point: Vector2 = Vector2.ZERO if line.points.is_empty() else line.points[-1]
		var point: Vector2 = query.position - global_position
		if record_point_state and not point_states.has(point):
			point_states[point] = DiscreteScreenPuzzleState.new(
				current_ag != null,
				orbiting,
				overlapping_areas,
				previous_point
			)
		line.add_point(point)
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

func launch_success():
	pass