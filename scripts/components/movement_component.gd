class_name MovementComponent
extends Node

## Responsive 2D action-platform movement: fast direction changes, forgiving
## jump timing, stronger falling gravity, air control and an energy-paid dash.

@export_group("Horizontal Movement")
@export var run_speed: float = 315.0
@export var sprint_multiplier: float = 1.28
@export var ground_acceleration: float = 4300.0
@export var ground_turn_acceleration: float = 5600.0
@export var ground_deceleration: float = 5000.0
@export var air_acceleration: float = 2200.0
@export var air_deceleration: float = 1350.0
@export var shield_move_multiplier: float = 0.40

@export_group("Jumping")
@export var jump_velocity: float = -605.0
@export var gravity_rising: float = 1540.0
@export var gravity_apex: float = 760.0
@export var gravity_falling: float = 2360.0
@export var max_fall_speed: float = 1050.0
@export var apex_velocity_window: float = 110.0
@export_range(0.1, 1.0) var jump_cut_multiplier: float = 0.50

@export_group("Jump Assistance")
@export var coyote_time: float = 0.13
@export var jump_buffer_time: float = 0.15

@export_group("Dash")
@export var dash_speed: float = 760.0
@export var dash_end_speed: float = 390.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.25
@export_range(0.0, 1.0) var dash_invulnerability_fraction: float = 0.58

var facing_direction: float = 1.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: float = 1.0
var _dash_available: bool = true
var _dashing: bool = false
var _dash_was_pressed: bool = false
var _air_jumps_remaining: int = 1
var _sprint_active: bool = false
var _jumped_this_frame: bool = false


func physics_tick(body: CharacterBody2D, delta: float) -> void:
	var grounded: bool = body.is_on_floor()
	_jumped_this_frame = false

	if body.has_method("is_staggered") and bool(body.call("is_staggered")):
		return

	if grounded:
		_air_jumps_remaining = 1
		if not _dashing:
			_dash_available = true

	_update_timers(grounded, delta)

	var direction: float = Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction):
		facing_direction = signf(direction)

	var blocking: bool = false
	if body.has_method("is_blocking"):
		blocking = bool(body.call("is_blocking"))

	var stamina: Node = body.get_node_or_null("StaminaComponent")
	_sprint_active = false
	if (
		stamina != null
		and grounded
		and not blocking
		and not _dashing
		and absf(direction) > 0.01
		and Input.is_physical_key_pressed(KEY_CTRL)
	):
		_sprint_active = bool(
			stamina.call("spend", float(stamina.get("sprint_per_second")) * delta)
		)

	var dash_pressed: bool = _dash_input_pressed()
	var dash_just_pressed: bool = dash_pressed and not _dash_was_pressed
	_dash_was_pressed = dash_pressed

	if (
		dash_just_pressed
		and not blocking
		and _dash_available
		and _dash_cooldown_timer <= 0.0
		and not _dashing
	):
		_start_dash(body, direction)

	if _dashing:
		_update_dash(body, delta)
	else:
		_update_horizontal(body, grounded, direction, blocking, delta)
		_update_vertical(body, grounded, delta)

	body.move_and_slide()


func _update_timers(grounded: bool, delta: float) -> void:
	if grounded:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)


func _update_horizontal(
	body: CharacterBody2D,
	grounded: bool,
	direction: float,
	blocking: bool,
	delta: float
) -> void:
	var speed_multiplier: float = 1.0
	if _sprint_active:
		speed_multiplier *= sprint_multiplier
	if blocking:
		speed_multiplier *= shield_move_multiplier
	if body.has_method("movement_speed_multiplier"):
		speed_multiplier *= float(body.call("movement_speed_multiplier"))

	var target_speed: float = direction * run_speed * speed_multiplier
	var acceleration: float

	if is_zero_approx(direction):
		acceleration = ground_deceleration if grounded else air_deceleration
	elif grounded and body.velocity.x * direction < -20.0:
		acceleration = ground_turn_acceleration
	else:
		acceleration = ground_acceleration if grounded else air_acceleration

	body.velocity.x = move_toward(
		body.velocity.x,
		target_speed,
		acceleration * delta
	)


func _update_vertical(body: CharacterBody2D, grounded: bool, delta: float) -> void:
	if not grounded:
		var current_gravity: float = gravity_rising
		if absf(body.velocity.y) <= apex_velocity_window:
			current_gravity = gravity_apex
		elif body.velocity.y > 0.0:
			current_gravity = gravity_falling
		body.velocity.y = minf(body.velocity.y + current_gravity * delta, max_fall_speed)
	elif body.velocity.y > 0.0:
		body.velocity.y = 0.0

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		var stamina: Node = body.get_node_or_null("StaminaComponent")
		var can_jump: bool = true
		if stamina != null:
			can_jump = bool(stamina.call("spend", float(stamina.get("jump_cost"))))
		if can_jump:
			body.velocity.y = jump_velocity
			_jumped_this_frame = true
			_jump_buffer_timer = 0.0
			_coyote_timer = 0.0

	if (
		not grounded
		and not _jumped_this_frame
		and _coyote_timer <= 0.0
		and Input.is_action_just_pressed("jump")
		and _air_jumps_remaining > 0
	):
		var second_jump_stamina: Node = body.get_node_or_null("StaminaComponent")
		var can_second_jump: bool = true
		if second_jump_stamina != null:
			can_second_jump = bool(second_jump_stamina.call("spend", float(second_jump_stamina.get("second_jump_cost"))))
		if can_second_jump:
			body.velocity.y = jump_velocity * 0.91
			_air_jumps_remaining -= 1
			_jump_buffer_timer = 0.0

	if Input.is_action_just_released("jump") and body.velocity.y < 0.0:
		body.velocity.y *= jump_cut_multiplier


func _dash_input_pressed() -> bool:
	if InputMap.has_action("dash"):
		return Input.is_action_pressed("dash") or Input.is_physical_key_pressed(KEY_SHIFT)
	return Input.is_physical_key_pressed(KEY_SHIFT)


func _start_dash(body: CharacterBody2D, direction: float) -> void:
	var stamina: Node = body.get_node_or_null("StaminaComponent")
	if stamina != null:
		if not bool(stamina.call("spend", float(stamina.get("dash_cost")))):
			return

	_dashing = true
	_dash_available = false
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dash_direction = signf(direction) if not is_zero_approx(direction) else facing_direction
	body.velocity = Vector2(_dash_direction * dash_speed, 0.0)


func _update_dash(body: CharacterBody2D, delta: float) -> void:
	_dash_timer = maxf(0.0, _dash_timer - delta)
	var progress: float = 1.0 - (_dash_timer / maxf(dash_duration, 0.001))
	var eased: float = 1.0 - pow(1.0 - progress, 2.0)
	var current_speed: float = lerpf(dash_speed, dash_end_speed, eased)
	body.velocity = Vector2(_dash_direction * current_speed, 0.0)

	if _dash_timer <= 0.0:
		_dashing = false
		body.velocity.x = _dash_direction * dash_end_speed


func cancel_dash_for_attack(body: CharacterBody2D) -> bool:
	if not _dashing:
		return false
	_dashing = false
	_dash_timer = 0.0
	body.velocity.x = _dash_direction * maxf(run_speed, dash_end_speed)
	return true


func is_dashing() -> bool:
	return _dashing


func is_dash_invulnerable() -> bool:
	if not _dashing:
		return false
	var progress: float = 1.0 - (_dash_timer / maxf(dash_duration, 0.001))
	return progress <= dash_invulnerability_fraction


func dash_progress() -> float:
	if not _dashing:
		return 0.0
	return clampf(1.0 - (_dash_timer / maxf(dash_duration, 0.001)), 0.0, 1.0)
