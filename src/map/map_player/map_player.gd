extends Node2D
class_name MapPlayer

const SPEED: float = 800
const ENERGY_USE_RATE: float = 30
## The player ends its movement when its center is within this distance of the
## center of the entrypoint
const DESTINATION_REACH_THRESHOLD = 20

const SHAKE = {
	TRAVEL_AMOUNT = 2.5,
	ORBIT_AMOUNT = 0.5,
	BOOST_AMOUNT = 5,
	LERP_SPEED = 1.0
}

signal select_destination(location: Entrypoint)

@onready var collision_box: Area2D = $PlayerBody
@onready var grav_component: GravitizedComponent = $GravitizedComponent
@onready var energy_bar: ProgressBar = $CanvasLayer/Energy
@onready var warning_label: Label = $CanvasLayer/WarningLabel
@onready var map_animation_player: AnimationPlayer = $MapAnimationPlayer
@onready var location_info: TextureRect = $CanvasLayer/TextBacker
@onready var destination_line: Line2D = $Line2D
@onready var boost_line: Line2D = $BoostLine2D

@onready var game: Game = get_tree().get_current_scene()
@onready var starting_position: Vector2 = global_position

## Used to determine the look of the lines. If orbit is ever used, trajectory
## and boost lines are shown until movement is ended.
var manual_control: bool = false
## Used to prevent manual control when crashing and to prevent multiple crash
## animations from being played.
var crashing = false
## Set true and false by entering and exiting cooland pockets
var in_coolant = false

var velocity: Vector2 = Vector2.ZERO

var moving = false:
	set(value):
		moving = value
		Global.moving_on_map = value

var destination: Entrypoint = null:
	set(value):
		destination = value
		if value:
			velocity = global_position.direction_to(value.global_position) * SPEED

## ----------------------------- CORE -----------------------------

func _ready() -> void:
	Global.pod_called.connect(_on_call_pod)

func _process(delta: float) -> void:
	if not moving:
		return
	
	var active_ag = grav_component.check_active_ag()
	var gravity_state = handle_artificial_gravity(active_ag, delta)

	global_position += velocity * delta

	draw_destination_line()
	draw_boost_line(active_ag)
	handle_manual_control_shake(gravity_state)
	handle_energy_consumption(delta)

	if is_destination_reached():
		end_movement(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		location_deselected()

## ----------------------------- HELPER -----------------------------

## Checks if we are within a threshold distance to the destination
func is_destination_reached() -> bool:
	if destination == null:
		return false
	return global_position.distance_to(destination.global_position) < DESTINATION_REACH_THRESHOLD

## ----------------------------- MOVING -----------------------------

func handle_artificial_gravity(active_ag: ArtificialGravity, delta) -> GravitizedComponent.GravityState:
	if not Global.pod_has_clicker:
		return GravitizedComponent.GravityState.NONE
	
	if crashing:
		return GravitizedComponent.GravityState.NONE
		
	var gravity_state = grav_component.determine_gravity_state(active_ag)
	if gravity_state != GravitizedComponent.GravityState.NONE:
		manual_control = true
		var new_vel = grav_component.calculate_gravitized_velocity(
			active_ag, gravity_state, velocity, delta
		)
		velocity = new_vel.normalized() * SPEED
	return gravity_state

## called once when you start travelling
func start_travel() -> void:
	if moving:
		return
	if is_destination_reached():
		return
	
	moving = true

	# Begin shake by setting target and regular speed
	Global.main_camera.start_shake()
	Global.main_camera.set_shake_lerp(SHAKE.TRAVEL_AMOUNT, SHAKE.LERP_SPEED)

## Called when you recall or when you reach destination
func end_movement(recalled: bool) -> void:
	moving = false
	manual_control = false

	velocity = Vector2.ZERO
	energy_bar.value = energy_bar.max_value
	starting_position = global_position

	location_deselected()
	location_info.show()

	if recalled:
		Global.main_camera.set_shake_lerp(0, 4)
	else:
		successful_landing_animation()

## Recall due to running out of fuel or crashing
func recall() -> void:
	global_position = starting_position
	location_deselected()
	end_movement(true)

## ----------------------------- FUEL -----------------------------

func handle_energy_consumption(delta):
	if in_coolant:
		return
	
	energy_bar.value -= ENERGY_USE_RATE * delta

	# Play energy animations
	if energy_bar.value <= 0:
		recall()
		run_out_of_energy_animation() ## await this one and put recall after
	elif energy_bar.value <= energy_bar.max_value / 6:
		critical_energy_animation()
	elif energy_bar.value <= energy_bar.max_value / 2:
		low_energy_animation()

## -------------------------- MAP LOCATION FUNCTIONS --------------------------

func enter_coolant_pocket() -> void:
	energy_bar.value = energy_bar.max_value
	in_coolant = true
	map_animation_player.play("neutral")
	game.pod.pod_animation_player.play("neutral")
	
func exit_coolant_pocket() -> void:
	in_coolant = false

func check_entrypoint_exited():
	for area in collision_box.get_overlapping_areas():
		if area is MapLocation or area is Hazard:
			hit_hazard()

func hit_hazard() -> void:
	if not moving:
		return
	# Immune when in entrypoint
	for area in collision_box.get_overlapping_areas():
		if area is Entrypoint:
			return
	# Prevent playing crashing animation twice
	if crashing:
		return

	crashing = true
	velocity = Vector2.ZERO
	await crash_animation()
	recall()
	post_crash_animation()
	crashing = false

## ----------------------------- MAP INTERACTION -----------------------------

func location_selected(location: Entrypoint):
	if moving:
		return

	destination = location

	update_line(
		destination_line,
		(destination.global_position - global_position).limit_length(calculate_distance_per_energy())
	)
	select_destination.emit(location)
	location_info.show()

func location_deselected():
	if moving:
		return
		
	location_info.hide()
	destination = null
	destination_line.set_point_position(1, Vector2.ZERO)
	select_destination.emit(null)

## ------------------------- DRAW LINE -------------------------

func draw_destination_line():
	if manual_control:
		# Draw line in direction of velocity
		update_line(
			destination_line,
			velocity.normalized() * calculate_distance_per_energy()
		)
	else:
		# Draw line to destination
		update_line(
			destination_line,
			(destination.global_position - global_position).limit_length(calculate_distance_per_energy())
		)
		
func draw_boost_line(active_ag: ArtificialGravity):
	if manual_control and active_ag:
		# Draw boost line in line with center of active_ag
		update_line(
			boost_line,
			active_ag.global_position.direction_to(global_position) * calculate_distance_per_energy() / 2
		)
	else:
		# No line
		update_line(
			boost_line,
			Vector2.ZERO
		)

## Sets the second point of [line] to [new_point]
func update_line(line: Line2D, new_point: Vector2):
	line.set_point_position(1, new_point)

func calculate_distance_per_energy() -> float:
	return SPEED / (ENERGY_USE_RATE / energy_bar.max_value) * (energy_bar.value / energy_bar.max_value)

## ------------------------- ANIMATION -------------------------

func handle_manual_control_shake(gravity_state: GravitizedComponent.GravityState):
	match gravity_state:
		GravitizedComponent.GravityState.BOOST:
			Global.main_camera.set_shake_lerp(SHAKE.BOOST_AMOUNT, 2.0)
		GravitizedComponent.GravityState.ORBIT:
			Global.main_camera.target_shake_amount = SHAKE.ORBIT_AMOUNT

func successful_landing_animation():
	map_animation_player.play("neutral")
	game.pod.pod_animation_player.play("neutral")
	Global.main_camera.set_shake_and_lerp_to_zero(40, 4)

func low_energy_animation() -> void:
	map_animation_player.play("LOW_ENERGY")

func critical_energy_animation() -> void:
	map_animation_player.play("OUT_OF_FUEL")
	game.pod.pod_animation_player.play("crash_warning")

func run_out_of_energy_animation() -> void:
	game.pod.pod_animation_player.play("crash_blackout")
	Global.main_camera.set_focus(null)
	await get_tree().create_timer(.3).timeout
	map_animation_player.play("SHUTDOWN_AVOIDED")

func crash_animation():
	map_animation_player.play("COLLISION_IMMINENT")
	game.pod.pod_animation_player.play("crash_warning")
	Global.main_camera.shake_amount = SHAKE.TRAVEL_AMOUNT * 10
	Global.main_camera.set_shake_lerp(SHAKE.TRAVEL_AMOUNT * 3, 20)
	await get_tree().create_timer(.4).timeout

	Global.main_camera.set_shake_lerp(SHAKE.TRAVEL_AMOUNT * 40, 0.5)
	
	await get_tree().create_timer(.8).timeout

	game.pod.pod_animation_player.play("crash_blackout")
	Global.main_camera.set_focus(null)
	# adds some time for screen to black out so player doesn't see lag caused by recall()
	await get_tree().create_timer(.2).timeout

## Happens after recalling due to crash
func post_crash_animation():
	await get_tree().create_timer(.3).timeout
	map_animation_player.play("IMPACT_AVOIDED")

## ------------------------- SIGNAL HANDLES -------------------------

func _area_scanned(area: Area2D) -> void:
	if area is MapLocation:
		if not area.locked && !area.visible:
			var base_modulate: Color = area.modulate
			area.modulate = Color(1, 1, 1, 0)
			area.show()
			var tween = get_tree().create_tween()
			tween.tween_property(area, "modulate", base_modulate, 1)

func _on_call_pod(empty_pod: EmptyPod) -> void:
	var current_level: MapLevel
	for area in collision_box.get_overlapping_areas():
		if area is Entrypoint:
			current_level = area.get_parent()

	for entry_point in current_level.get_children():
		if entry_point is Entrypoint and entry_point.entry_number == empty_pod.entry_number:
			entry_point.pod_called()
			global_position = entry_point.global_position

func _on_travel_button_pressed():
	start_travel()
