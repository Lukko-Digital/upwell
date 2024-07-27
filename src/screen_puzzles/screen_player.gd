@tool
extends Node2D
class_name ScreenPlayer

# @export var STARTING_POWER: float = 1000
# const SPACING: float = 2
const STARTING_POWER: float = 200
const SPACING: float = 10

@onready var line: Line2D = $Line2D
@onready var line_area: Area2D = $Line2D/LineCollisionArea

func _ready() -> void:
	update_tragectory()

## Returns the folder that was hit, if no folder was hit, returns null
func update_tragectory() -> ScreenCore:
	line.clear_points()
	clear_collision_segments()

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
		for area in overlapping:
			if area.collider is ScreenAG:
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
		spawn_collision_segment()
		query.position += dir * SPACING
		power -= 1
	return null

func clear_collision_segments():
	for child in line_area.get_children():
		line_area.remove_child.call_deferred(child)
		child.queue_free()

func spawn_collision_segment():
	var points = line.points
	if points.size() < 2:
		return
	var collision = CollisionShape2D.new()
	var segment = SegmentShape2D.new()
	segment.a = points[- 1]
	segment.b = points[- 2]
	collision.shape = segment
	line_area.add_child.call_deferred(collision)

# func _process(_delta: float) -> void:
# 	update_tragectory()
	# print(line_area.get_child_count())