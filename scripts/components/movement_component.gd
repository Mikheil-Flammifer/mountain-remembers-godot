
class_name MovementComponent
extends Node

## Reusable 2D platformer movement component.
## Handles ground movement, air movement, jumping,
## gravity, jump buffering, and coyote time.

@export_group("Horizontal Movement")
@export var run_speed: float = 270.0
@export var ground_acceleration: float = 1800.0
@export var ground_deceleration: float = 2200.0
@export var air_acceleration: float = 1250.0
@export var air_deceleration: float = 950.0

@export_group("Vertical Movement")
@export var gravity: float = 1450.0
@export var jump_velocity: float = -470.0
@export var max_fall_speed: float = 900.0
@export_range(0.1, 1.0) var jump_cut_multiplier: float = 0.45

@export_group("Jump Assistance")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.14

var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0


func physics_tick(body: CharacterBody2D, delta: float) -> void:
	var grounded: bool = body.is_on_floor()

	_update_timers(grounded, delta)
	_handle_horizontal_movement(body, grounded, delta)

	if _can_jump():
		_perform_jump(body)
		grounded = false

	_handle_jump_release(body)
	_apply_gravity(body, grounded, delta)

	body.move_and_slide()


func _update_timers(grounded: bool, delta: float) -> void:
	if grounded:
		_coyote_remaining = coyote_time
	else:
		_coyote_remaining = maxf(
			_coyote_remaining - delta,
			0.0
		)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_remaining = jump_buffer_time
	else:
		_jump_buffer_remaining = maxf(
			_jump_buffer_remaining - delta,
			0.0
		)


func _handle_horizontal_movement(
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


func _can_jump() -> bool:
	return (
		_jump_buffer_remaining > 0.0
		and _coyote_remaining > 0.0
	)


func _perform_jump(body: CharacterBody2D) -> void:
	body.velocity.y = jump_velocity

	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0


func _handle_jump_release(body: CharacterBody2D) -> void:
	if Input.is_action_just_released("jump"):
		if body.velocity.y < 0.0:
			body.velocity.y *= jump_cut_multiplier


func _apply_gravity(
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
