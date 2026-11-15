
class_name MovementComponent
extends Node

## Responsive movement with ground/air control,
## variable jumping, coyote time, jump buffering,
## and one air dash before landing.

@export_group("Horizontal Movement")
@export var run_speed: float = 320.0
@export var ground_acceleration: float = 2600.0
@export var ground_deceleration: float = 3000.0
@export var air_acceleration: float = 1900.0
@export var air_deceleration: float = 1200.0

@export_group("Jumping")
@export var jump_velocity: float = -540.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 950.0
@export_range(0.1, 1.0) var jump_cut_multiplier: float = 0.45

@export_group("Jump Assistance")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.14

@export_group("Dash")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.17
@export var dash_cooldown: float = 0.30

var facing_direction: float = 1.0

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: float = 1.0
var _dash_available: bool = true
var _dashing: bool = false
var _dash_was_pressed: bool = false


func physics_tick(
	body: CharacterBody2D,
	delta: float
) -> void:
	var grounded: bool = body.is_on_floor()

	_update_timers(grounded, delta)

	var direction: float = Input.get_axis(
		"move_left",
		"move_right"
	)

	if not is_zero_approx(direction):
		facing_direction = signf(direction)

	var dash_pressed: bool = _dash_input_pressed()
	var dash_just_pressed: bool = (
		dash_pressed and not _dash_was_pressed
	)
	_dash_was_pressed = dash_pressed

	if grounded and not _dashing:
		_dash_available = true

	if (
		dash_just_pressed
		and _dash_available
		and _dash_cooldown_timer <= 0.0
		and not _dashing
	):
		_start_dash(body, direction)

	if _dashing:
		_update_dash(body, delta)
	else:
		_update_horizontal(body, grounded, direction, delta)
		_update_vertical(body, grounded, delta)

	body.move_and_slide()


func _update_timers(
	grounded: bool,
	delta: float
) -> void:
	if grounded:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(
			_coyote_timer - delta,
			0.0
		)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(
			_jump_buffer_timer - delta,
			0.0
		)

	_dash_cooldown_timer = maxf(
		_dash_cooldown_timer - delta,
		0.0
	)


func _update_horizontal(
	body: CharacterBody2D,
	grounded: bool,
	direction: float,
	delta: float
) -> void:
	var target_speed: float = direction * run_speed
	var acceleration: float

	if is_zero_approx(direction):
		acceleration = (
			ground_deceleration
			if grounded
			else air_deceleration
		)
	else:
		acceleration = (
			ground_acceleration
			if grounded
			else air_acceleration
		)

	body.velocity.x = move_toward(
		body.velocity.x,
		target_speed,
		acceleration * delta
	)


func _update_vertical(
	body: CharacterBody2D,
	grounded: bool,
	delta: float
) -> void:
	if not grounded:
		body.velocity.y = minf(
			body.velocity.y + gravity * delta,
			max_fall_speed
		)
	elif body.velocity.y > 0.0:
		body.velocity.y = 0.0

	if (
		_jump_buffer_timer > 0.0
		and _coyote_timer > 0.0
	):
		body.velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	if Input.is_action_just_released("jump"):
		if body.velocity.y < 0.0:
			body.velocity.y *= jump_cut_multiplier


func _dash_input_pressed() -> bool:
	# Shift works immediately. A custom "dash"
	# Input Map action can also be used later.
	if InputMap.has_action("dash"):
		return (
			Input.is_action_pressed("dash")
			or Input.is_physical_key_pressed(KEY_SHIFT)
		)

	return Input.is_physical_key_pressed(KEY_SHIFT)


func _start_dash(
	body: CharacterBody2D,
	direction: float
) -> void:
	_dashing = true
	_dash_available = false
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown

	_dash_direction = (
		signf(direction)
		if not is_zero_approx(direction)
		else facing_direction
	)

	body.velocity = Vector2(
		_dash_direction * dash_speed,
		0.0
	)


func _update_dash(
	body: CharacterBody2D,
	delta: float
) -> void:
	_dash_timer -= delta

	body.velocity = Vector2(
		_dash_direction * dash_speed,
		0.0
	)

	if _dash_timer <= 0.0:
		_dashing = false
		body.velocity.x = _dash_direction * run_speed

func is_dashing() -> bool:
	return _dashing
