class_name SwordCombatComponent
extends Node

## Simple melee combat component for Xizane.
## Handles attack timing, active hit frames, and damage application.

signal attack_started
signal attack_finished
signal hit_landed(target)

@export var attack_duration: float = 0.24
@export var active_start: float = 0.06
@export var active_end: float = 0.16
@export var damage: int = 1
@export var knockback_force: float = 240.0

@onready var hitbox: Area2D = $AttackHitbox
@onready var collision: CollisionShape2D = $AttackHitbox/CollisionShape2D

var _attacking: bool = false
var _attack_timer: float = 0.0
var _already_hit: Array[Node] = []

func _ready() -> void:
	if collision != null:
		collision.disabled = true

func physics_tick(owner_body: CharacterBody2D, facing_direction: float, delta: float) -> void:
	if _attacking:
		_attack_timer += delta

		_update_hitbox_state(owner_body, facing_direction)

		if _attack_timer >= attack_duration:
			_finish_attack()

func try_start_attack() -> bool:
	if _attacking:
		return false

	_attacking = true
	_attack_timer = 0.0
	_already_hit.clear()

	emit_signal("attack_started")
	return true

func is_attacking() -> bool:
	return _attacking

func _update_hitbox_state(owner_body: CharacterBody2D, facing_direction: float) -> void:
	if hitbox == null or collision == null:
		return

	var active: bool = (
		_attack_timer >= active_start
		and _attack_timer <= active_end
	)

	collision.disabled = not active

	if facing_direction >= 0.0:
		hitbox.position.x = 28.0
		hitbox.scale.x = 1.0
	else:
		hitbox.position.x = -28.0
		hitbox.scale.x = -1.0

	if active:
		_apply_hits(owner_body, facing_direction)

func _apply_hits(owner_body: CharacterBody2D, facing_direction: float) -> void:
	var targets: Array[Node2D] = hitbox.get_overlapping_bodies()
	var overlap_areas: Array[Area2D] = hitbox.get_overlapping_areas()

	for body in targets:
		if body == owner_body:
			continue
		if _already_hit.has(body):
			continue

		_already_hit.append(body)
		_apply_damage(body, facing_direction)
		emit_signal("hit_landed", body)

	for area in overlap_areas:
		if area == hitbox:
			continue
		if _already_hit.has(area):
			continue

		_already_hit.append(area)
		_apply_damage(area, facing_direction)
		emit_signal("hit_landed", area)

func _apply_damage(target: Node, facing_direction: float) -> void:
	if target == null:
		return

	var knockback := Vector2(facing_direction * knockback_force, -70.0)

	if target.has_method("take_hit"):
		target.call("take_hit", damage, knockback)
	elif target.has_method("take_damage"):
		target.call("take_damage", damage, knockback)

func _finish_attack() -> void:
	_attacking = false
	_attack_timer = 0.0

	if collision != null:
		collision.disabled = true

	emit_signal("attack_finished")