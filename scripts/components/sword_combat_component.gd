
class_name SwordCombatComponent
extends Node

signal attack_started
signal attack_finished
signal hit_landed(target: Node)

@export_group("Sword Attack")
@export var damage: int = 1
@export var attack_duration: float = 0.32
@export var active_start: float = 0.09
@export var active_end: float = 0.24
@export var attack_cooldown: float = 0.12
@export var knockback_force: float = 250.0

@onready var hitbox: Area2D = $AttackHitbox
@onready var collision: CollisionShape2D = $AttackHitbox/CollisionShape2D

var _attacking: bool = false
var _elapsed: float = 0.0
var _cooldown_remaining: float = 0.0
var _hit_targets: Array[Node] = []


func _ready() -> void:
	# We use the shape for direct physics queries,
	# so the Area2D does not need to detect overlaps.
	hitbox.monitoring = false
	hitbox.monitorable = false
	collision.disabled = true


func physics_tick(
	owner_body: CharacterBody2D,
	facing_direction: float,
	delta: float
) -> void:
	_cooldown_remaining = maxf(
		_cooldown_remaining - delta,
		0.0
	)

	if not _attacking:
		return

	_elapsed += delta

	# Keep the hitbox in front of the character.
	var facing: float = (
		1.0 if facing_direction >= 0.0 else -1.0
	)

	hitbox.position = Vector2(
		34.0 * facing,
		-10.0
	)

	if _elapsed >= active_start and _elapsed <= active_end:
		_check_hits(owner_body, facing)

	if _elapsed >= attack_duration:
		_finish_attack()


func try_start_attack() -> bool:
	if _attacking or _cooldown_remaining > 0.0:
		return false

	_attacking = true
	_elapsed = 0.0
	_hit_targets.clear()

	attack_started.emit()
	return true


func is_attacking() -> bool:
	return _attacking


func attack_progress() -> float:
	if not _attacking:
		return 0.0

	return clampf(
		_elapsed / maxf(attack_duration, 0.001),
		0.0,
		1.0
	)


func _check_hits(
	owner_body: CharacterBody2D,
	facing: float
) -> void:
	if collision.shape == null:
		return

	var query := PhysicsShapeQueryParameters2D.new()

	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = hitbox.collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [owner_body.get_rid()]

	var results: Array[Dictionary] = (
		owner_body.get_world_2d()
		.direct_space_state
		.intersect_shape(query, 16)
	)

	for result: Dictionary in results:
		var target: Node = result.get("collider") as Node

		if target == null:
			continue

		if _hit_targets.has(target):
			continue

		if not (
			target.has_method("take_hit")
			or target.has_method("take_damage")
		):
			continue

		_hit_targets.append(target)

		var knockback := Vector2(
			facing * knockback_force,
			-80.0
		)

		if target.has_method("take_hit"):
			target.call("take_hit", damage, knockback)
		else:
			target.call("take_damage", damage, knockback)

		hit_landed.emit(target)


func _finish_attack() -> void:
	_attacking = false
	_elapsed = 0.0
	_cooldown_remaining = attack_cooldown
	_hit_targets.clear()

	attack_finished.emit()
