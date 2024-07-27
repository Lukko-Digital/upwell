@tool
extends Node2D
class_name ScreenPlayer

# @export var STARTING_POWER: float = 1000
# const SPACING: float = 2
const STARTING_POWER: float = 200
const SPACING: float = 10

@onready var trajectory_line: Line2D = %TrajectoryLine
@onready var line_area: TrajectoryLineArea = %LineCollisionArea
@onready var new_action_line: Line2D = %NewActionLine

func _ready() -> void:
	init_collision_segments()
	update_main_line()

func update_main_line():
	update_trajectory(trajectory_line)
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
	var can_power_up = true

	while power > 0:
		var powered_up = false
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
				if can_power_up:
					power += area.power
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

func init_collision_segments():
	for _i in range(STARTING_POWER):
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
