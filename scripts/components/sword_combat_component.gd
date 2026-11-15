
class_name SwordCombatComponent
extends Node

## Xizane's directional sword combat.
##
## Forward: H
## Upward: W + H
## Downward: S + H while airborne
##
## Uses direct physics shape queries for reliable damage.
## Each enemy can only be hit once per attack.

signal attack_started
signal attack_finished
signal hit_landed(target: Node)

@export_group("Combat")
@export var damage: int = 10
@export var attack_duration: float = 0.30
@export var active_start: float = 0.08
@export var active_end: float = 0.21
@export var attack_cooldown: float = 0.13
@export var knockback_force: float = 250.0
@export var pogo_velocity: float = -440.0

@export_group("Hitbox")
@export var forward_hitbox_size: Vector2 = Vector2(80, 65)
@export var vertical_hitbox_size: Vector2 = Vector2(65, 80)
@export_flags_2d_physics var enemy_collision_mask: int = 1

@export_group("Debug")
@export var debug_hits: bool = false

@onready var hitbox: Area2D = $AttackHitbox
@onready var collision: CollisionShape2D = (
	$AttackHitbox/CollisionShape2D
)

var _attacking: bool = false
var _elapsed: float = 0.0
var _cooldown_remaining: float = 0.0

var _direction: String = "forward"
var _attack_facing: float = 1.0

var _hit_targets: Array[Node] = []

var _query_shape: RectangleShape2D


func _ready() -> void:
	# We use manual physics queries instead of Area2D signals.
	hitbox.monitoring = false
	hitbox.monitorable = false

	# Keep the original collision disabled.
	collision.disabled = true

	# A separate shape avoids depending on disabled
	# CollisionShape2D physics synchronization.
	_query_shape = RectangleShape2D.new()
	_query_shape.size = forward_hitbox_size

	if debug_hits:
		print("[Sword] Combat component ready")


func try_start_attack(
	direction: String = "forward",
	facing: float = 1.0
) -> bool:
	if _attacking:
		return false

	if _cooldown_remaining > 0.0:
		return false

	if direction not in ["forward", "up", "down"]:
		return false

	_attacking = true
	_elapsed = 0.0

	_direction = direction
	_attack_facing = 1.0 if facing >= 0.0 else -1.0

	_hit_targets.clear()

	if debug_hits:
		print("[Sword] Attack started: ", _direction)

	attack_started.emit()

	return true


func physics_tick(
	owner_body: CharacterBody2D,
	_facing_direction: float,
	delta: float
) -> void:
	_cooldown_remaining = maxf(
		_cooldown_remaining - delta,
		0.0
	)

	if not _attacking:
		return

	_elapsed += delta

	_update_hitbox_position()

	if (
		_elapsed >= active_start
		and _elapsed <= active_end
	):
		_check_hits(owner_body)

	if _elapsed >= attack_duration:
		_finish_attack()


func _update_hitbox_position() -> void:
	match _direction:
		"up":
			hitbox.position = Vector2(0.0, -55.0)
			hitbox.rotation = 0.0
			_query_shape.size = vertical_hitbox_size

		"down":
			hitbox.position = Vector2(0.0, 55.0)
			hitbox.rotation = 0.0
			_query_shape.size = vertical_hitbox_size

		_:
			hitbox.position = Vector2(
				45.0 * _attack_facing,
				-10.0
			)
			hitbox.rotation = 0.0
			_query_shape.size = forward_hitbox_size


func _check_hits(owner_body: CharacterBody2D) -> void:
	var space_state: PhysicsDirectSpaceState2D = (
		owner_body.get_world_2d().direct_space_state
	)

	var query := PhysicsShapeQueryParameters2D.new()

	query.shape = _query_shape

	# Calculate the attack position directly from Xizane.
	# This avoids relying on the disabled hitbox's
	# collision synchronization.
	var world_position: Vector2 = owner_body.to_global(
		hitbox.position
	)

	query.transform = Transform2D(
		0.0,
		world_position
	)

	query.collision_mask = enemy_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	# Never hit Xizane with his own sword.
	query.exclude = [owner_body.get_rid()]

	var results: Array[Dictionary] = (
		space_state.intersect_shape(query, 32)
	)

	if debug_hits:
		print(
			"[Sword] Direction: ",
			_direction,
			" | Colliders: ",
			results.size()
		)

	for result: Dictionary in results:
		var target: Node = result.get("collider") as Node

		if target == null:
			continue

		if target == owner_body:
			continue

		if _hit_targets.has(target):
			continue

		if debug_hits:
			print("[Sword] Detected: ", target.name)

		# Only objects supporting sword damage may be hit.
		if not target.has_method("take_hit"):
			continue

		_hit_targets.append(target)

		var knockback: Vector2 = _calculate_knockback()

		# The mountain wolf and training dummy both
		# support take_hit(amount, knockback).
		target.call(
			"take_hit",
			damage,
			knockback
		)

		hit_landed.emit(target)

		if debug_hits:
			print(
				"[Sword] Hit ",
				target.name,
				" for ",
				damage,
				" damage"
			)

		# Downward sword hits bounce Xizane upward.
		if (
			_direction == "down"
			and not owner_body.is_on_floor()
		):
			owner_body.velocity.y = pogo_velocity


func _calculate_knockback() -> Vector2:
	match _direction:
		"up":
			return Vector2(
				0.0,
				-knockback_force
			)

		"down":
			return Vector2(
				0.0,
				knockback_force
			)

		_:
			return Vector2(
				_attack_facing * knockback_force,
				-80.0
			)


func is_attacking() -> bool:
	return _attacking


func attack_direction() -> String:
	return _direction


func attack_progress() -> float:
	if not _attacking:
		return 0.0

	return clampf(
		_elapsed / maxf(attack_duration, 0.001),
		0.0,
		1.0
	)


func _finish_attack() -> void:
	_attacking = false
	_elapsed = 0.0
	_cooldown_remaining = attack_cooldown

	_hit_targets.clear()

	if debug_hits:
		print("[Sword] Attack finished")

	attack_finished.emit()
