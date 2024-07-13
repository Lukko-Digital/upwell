extends RigidBody2D
class_name ClickerBody

## Only needs to be set when a clicker doesn't start in a holder. Holders will
## set the home of clickers that they start with.
@export var home_holder: ClickerHolder = null
@export var grav_component: GravitizedComponent
@export var glow_sprite: Sprite2D
@export var lights_sprite: Sprite2D
@export var interactable: Interactable

## Value set by [Player]. Player can only control the closest n clickers, where
## n is the number of clickers the player is holding.
var controllable: bool = false:
	set = set_controllable
## Set false when dropped to prevent immediately re-entering holder
var catchable: bool = true
## Value is set by [ClickerHolder] when clicker is inserted/removed
var holder_owned_by: ClickerHolder

func set_controllable(value: bool):
	lights_sprite.visible = value
	controllable = value

func _ready() -> void:
	add_to_group("Clickers")

func _physics_process(delta: float) -> void:
	var gravity_state: GravitizedComponent.GravityState = handle_artificial_gravity(delta)
	if gravity_state == GravitizedComponent.GravityState.ORBIT:
		gravity_scale = 0
		handle_leave_clicker()
	else:
		gravity_scale = 1

func _process(_delta):
	handle_animation()

func handle_artificial_gravity(delta) -> GravitizedComponent.GravityState:
	if not controllable:
		return GravitizedComponent.GravityState.NONE
	var active_ag = grav_component.check_active_ag()
	var gravity_state = grav_component.determine_gravity_state(active_ag)
	if gravity_state != GravitizedComponent.GravityState.NONE:
		var new_vel = grav_component.calculate_gravitized_velocity(
			active_ag, gravity_state, linear_velocity, delta
		)
		linear_velocity = new_vel
	return gravity_state

func handle_animation():
	if (Input.is_action_pressed("orbit") and controllable) or interactable.highlighted:
		glow_sprite.show()
	elif !interactable.highlighted:
		glow_sprite.hide()

## Clicker can get pulled out of a holder by orbit
func handle_leave_clicker():
	if Input.is_action_just_pressed("orbit") and holder_owned_by != null:
		holder_owned_by.drop_clicker()

func return_to_home():
	# Bump existing clicker
	if home_holder.has_clicker() and home_holder.owned_clicker != self:
		home_holder.owned_clicker.return_to_home()
	home_holder.owned_clicker = self

func _on_holder_detector_area_entered(area: Area2D) -> void:
	if not area is ClickerHolder:
		return
	if not (
		catchable and
		area.is_catcher and
		area.owned_clicker == null
	):
		return

	area.owned_clicker = self

func _on_holder_detector_area_exited(area: Area2D) -> void:
	if area is ClickerHolder:
		catchable = true