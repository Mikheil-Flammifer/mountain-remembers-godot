
class_name MovementComponent
extends Node

## Responsive 2D platformer movement.
## Supports:
## - Ground and air acceleration
## - Variable-height jumping
## - Coyote time
## - Jump buffering
## - Maximum falling speed

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

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0


func physics_tick(
	body: CharacterBody2D,
	delta: float
) -> void:
	var grounded: bool = body.is_on_floor()

	_update_timers(grounded, delta)
	_update_horizontal(body, grounded, delta)
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


func _update_horizontal(
	body: CharacterBody2D,
	grounded: bool,
	delta: float
) -> void:
	var direction: float = Input.get_axis(
		"move_left",
		"move_right"
	)

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
	# Apply gravity only when airborne.
	if not grounded:
		body.velocity.y = minf(
			body.velocity.y + gravity * delta,
			max_fall_speed
		)
	elif body.velocity.y > 0.0:
		body.velocity.y = 0.0

	# Buffered jump, including a short window
	# after leaving a platform.
	if (
		_jump_buffer_timer > 0.0
		and _coyote_timer > 0.0
	):
		body.velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# Releasing jump early produces a shorter jump.
	if Input.is_action_just_released("jump"):
		if body.velocity.y < 0.0:
			body.velocity.y *= jump_cut_multiplier
