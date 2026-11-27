
class_name ActorVisualState
extends RefCounted
## Runtime gameplay state consumed by an actor's visual implementation.
## This class must not modify gameplay or contain rendering logic.


# Movement

var velocity: Vector2 = Vector2.ZERO
var facing_direction: float = 1.0
var run_speed: float = 1.0

var is_grounded: bool = false
var is_dashing: bool = false
var is_climbing: bool = false
var is_crouching: bool = false


# Combat

var is_attacking: bool = false
var is_blocking: bool = false
var is_staggered: bool = false

var attack_direction: String = "forward"
var attack_progress: float = 0.0
var combo_step: int = 0


# Actor condition

var is_dead: bool = false
var is_resting: bool = false
var is_healing: bool = false
var is_invulnerable: bool = false


# Visual effects

var shield_flash_timer: float = 0.0
var perfect_guard_flash_timer: float = 0.0
var heal_flash_timer: float = 0.0


# Derived movement states

func get_speed_ratio() -> float:
	return clampf(
		absf(velocity.x) / maxf(run_speed, 1.0),
		0.0,
		1.25
	)


func is_moving() -> bool:
	return absf(velocity.x) > 1.0


func is_running() -> bool:
	return (
		is_grounded
		and get_speed_ratio() > 0.08
		and not is_dashing
		and not is_attacking
		and not is_blocking
		and not is_resting
		and not is_dead
	)


func is_jumping() -> bool:
	return not is_grounded and velocity.y < 0.0


func is_falling() -> bool:
	return not is_grounded and velocity.y > 0.0


func is_idle() -> bool:
	return (
		is_grounded
		and not is_moving()
		and not is_attacking
		and not is_blocking
		and not is_dashing
		and not is_staggered
		and not is_resting
		and not is_dead
	)
