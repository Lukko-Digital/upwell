extends Node2D
class_name MapPlayer

@onready var line: Line2D = $Line2D

@onready var game: Game = get_tree().get_current_scene()
@onready var energy_bar: ProgressBar = $CanvasLayer/Energy
@onready var starting_position: Vector2 = global_position
@onready var collision_box: Area2D = $PlayerBody
@onready var warning_label: Label = $CanvasLayer/WarningLabel
@onready var grav_component: GravitizedComponent = $GravitizedComponent
@onready var map_animation_player: AnimationPlayer = $MapAnimationPlayer

const HAZARD_TEXT = "IMPACT AVOIDED"
const OUT_OF_ENERGY_TEXT = "RECALLED DUE TO ENERGY LOSS"
const LOW_ENERGY_TEXT = "You are low on energy"
const TRAVEL_SHAKE_AMOUNT = 2.5

var current_shake: float = 0.0
var target_shake: float = 0.0
var shake_lerp_speed: float = 1.0

var moving = false:
	set(value):
		moving = value
		Global.moving_on_map = value

var in_coolant = false

var velocity: Vector2 = Vector2.ZERO

var recalled = false

var destination: Entrypoint = null:
	set(value):
		destination = value
		velocity = global_position.direction_to(value.global_position) * SPEED

const SPEED: float = 800
const ENERGY_USE_RATE: float = 30

const AG_ACCELERATION: float = 4

func _ready() -> void:
	Global.pod_called.connect(_on_call_pod)

func _process(delta: float) -> void:
	if moving:
		var active_ag = grav_component.check_active_ag()
		var gravity_state = grav_component.determine_gravity_state(active_ag)
		if gravity_state != GravitizedComponent.GravityState.NONE and Global.pod_has_clicker:
			var new_vel = grav_component.calculate_gravitized_velocity(
				active_ag, gravity_state, velocity, delta
			)
			velocity = new_vel.normalized() * SPEED
			target_shake = TRAVEL_SHAKE_AMOUNT / 5

		global_position += velocity * delta
		if global_position.distance_to(destination.global_position) < 20:
			end_movement()
		else:
			line.set_point_position(1, destination.global_position - global_position)

		if not in_coolant: energy_bar.value -= ENERGY_USE_RATE * delta
	
	if energy_bar.value <= 0:
		run_out_of_energy()
	elif energy_bar.value <= energy_bar.max_value / 5:
		critical_energy()
	elif energy_bar.value <= energy_bar.max_value / 2:
		# Turns out low energy warning is kinda annoying cause you hit it a lot
		# low_energy()
		pass

	#handle shake lerping
	lerp_shake(delta)

## Constantly lerps [current_shake] to a [target_shake] in order for smooth shake change
func lerp_shake(delta: float):
	current_shake = lerp(current_shake, target_shake, delta * shake_lerp_speed)
	if current_shake != target_shake:
		Global.camera_shake.emit(INF, current_shake)

func location_hovered(location: Entrypoint):
	if moving:
		return
	if line.get_point_count() < 2:
		line.add_point(location.global_position - global_position)

func location_unhovered(_location: Entrypoint):
	if moving:
		return
	if line.get_point_count() > 1:
		line.remove_point(1)

func location_selected(location: Entrypoint):
	# Commented out for playtesting purposes
	if moving: # or drill_heat > 0:
		return
	destination = location
	moving = true

	# Begin shake by setting target and regular speed
	shake_lerp_speed = 1
	target_shake = TRAVEL_SHAKE_AMOUNT

func enter_coolant_pocket() -> void:
	energy_bar.value = energy_bar.max_value
	in_coolant = true
	target_shake = TRAVEL_SHAKE_AMOUNT
	map_animation_player.play("neutral")
	game.pod.pod_animation_player.play("neutral")
	
func exit_coolant_pocket() -> void:
	in_coolant = false

func end_movement() -> void:

	moving = false

	velocity = Vector2.ZERO
	energy_bar.value = energy_bar.max_value
	starting_position = global_position
	if line.get_point_count() > 1:
		line.remove_point(1)

	if recalled:
		current_shake = shake_lerp_speed / 10
		shake_lerp_speed = 4.0
		target_shake = 0
		recalled = false
	else: # Increase shape for landing and kill it quickly
		map_animation_player.play("neutral")
		game.pod.pod_animation_player.play("neutral")
		current_shake = shake_lerp_speed * 40
		shake_lerp_speed = 4.0
		target_shake = 0
		# 7/13, josh says dont bump you out of map on arrival
		# await get_tree().create_timer(0.35).timeout
		# Global.set_camera_focus.emit(null)
		recalled = false

func recall() -> void:
	recalled = true
	global_position = starting_position
	end_movement()

func show_warning(warning_text: String) -> void:
	warning_label.text = warning_text
	warning_label.show()
	await get_tree().create_timer(2).timeout
	warning_label.hide()

func low_energy() -> void:
	map_animation_player.play("LOW_ENERGY")

func critical_energy() -> void:
	map_animation_player.play("OUT_OF_FUEL")
	game.pod.pod_animation_player.play("crash_warning")
	target_shake = TRAVEL_SHAKE_AMOUNT * 4

func run_out_of_energy() -> void:
	game.pod.pod_animation_player.play("crash_blackout")
	recall()
	Global.set_camera_focus.emit(null) # (game.pod.point_focus_marker)
	await get_tree().create_timer(.3).timeout
	map_animation_player.play("SHUTDOWN_AVOIDED")

func hit_hazard() -> void:
	for area in collision_box.get_overlapping_areas():
		if area is Entrypoint:
			return

	velocity = velocity * 0.5
	map_animation_player.play("COLLISION_IMMINENT")
	game.pod.pod_animation_player.play("crash_warning")
	current_shake = TRAVEL_SHAKE_AMOUNT * 10
	shake_lerp_speed = 20
	target_shake = TRAVEL_SHAKE_AMOUNT * 3
	await get_tree().create_timer(.4).timeout

	shake_lerp_speed = .5
	target_shake = TRAVEL_SHAKE_AMOUNT * 40
	
	await get_tree().create_timer(.8).timeout

	game.pod.pod_animation_player.play("crash_blackout")
	Global.set_camera_focus.emit(null) # (game.pod.point_focus_marker)
	await get_tree().create_timer(.2).timeout # adds some time for screen to black out so player doesn't see lag caused by recall()
	recall()
	await get_tree().create_timer(.3).timeout

	map_animation_player.play("IMPACT_AVOIDED")

func _area_scanned(area: Area2D) -> void:
	if area is MapLocation:
		if not area.locked&&!area.visible:
			var base_modulate: Color = area.modulate
			area.modulate = Color(1, 1, 1, 0)
			area.show()
			var tween = get_tree().create_tween()
			tween.tween_property(area, "modulate", base_modulate, 1)

func check_entrypoint_exited():
	for area in collision_box.get_overlapping_areas():
		if area is MapLocation or area is Hazard:
			hit_hazard()
			return

func _on_call_pod(empty_pod: EmptyPod) -> void:
	var current_level = destination.get_parent()

	for entry_point in current_level.get_children():
		if entry_point is Entrypoint and entry_point.entry_number == empty_pod.entry_number:
			entry_point.pod_called()
			global_position = entry_point.global_position
