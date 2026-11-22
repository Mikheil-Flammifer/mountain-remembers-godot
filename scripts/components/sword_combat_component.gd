class_name SwordCombatComponent
extends Node

## Mountain Blade combat with a buffered two-swing ground combo, directional
## anti-air/downward attacks and a short active hit window.

signal attack_started
signal attack_finished
signal hit_landed(target: Node)

@export_group("Combat")
@export var damage: int = 8
@export var attack_duration: float = 0.34
@export var active_start: float = 0.075
@export var active_end: float = 0.225
@export var attack_cooldown: float = 0.07
@export var combo_buffer_start: float = 0.40
@export var knockback_force: float = 325.0
@export var pogo_velocity: float = -475.0
@export var dash_attack_multiplier: float = 1.22

@export_group("Hitbox")
@export var forward_hitbox_size: Vector2 = Vector2(116.0, 92.0)
@export var vertical_hitbox_size: Vector2 = Vector2(106.0, 196.0)
@export_flags_2d_physics var enemy_collision_mask: int = 1

@export_group("Debug")
@export var debug_hits: bool = false

@onready var hitbox: Area2D = $AttackHitbox
@onready var collision: CollisionShape2D = $AttackHitbox/CollisionShape2D

var _attacking: bool = false
var _elapsed: float = 0.0
var _cooldown_remaining: float = 0.0
var _direction: String = "forward"
var _attack_facing: float = 1.0
var _power_scale: float = 1.0
var _combo_step: int = 0
var _buffered_attack: bool = false
var _buffered_direction: String = "forward"
var _buffered_facing: float = 1.0
var _hit_targets: Array[Node] = []
var _query_shape: RectangleShape2D


func _ready() -> void:
	hitbox.monitoring = false
	hitbox.monitorable = false
	collision.disabled = true
	_query_shape = RectangleShape2D.new()
	_query_shape.size = forward_hitbox_size


func try_start_attack(
	direction: String = "forward",
	facing: float = 1.0,
	power_scale: float = 1.0
) -> bool:
	if direction not in ["forward", "up", "down"]:
		return false

	var player: Node = get_parent()
	if player.has_method("is_staggered") and bool(player.call("is_staggered")):
		return false

	if _attacking:
		var progress: float = attack_progress()
		if progress >= combo_buffer_start and _direction == "forward" and direction == "forward":
			_buffered_attack = true
			_buffered_direction = direction
			_buffered_facing = 1.0 if facing >= 0.0 else -1.0
			return true
		return false

	if _cooldown_remaining > 0.0:
		return false

	return _begin_attack(direction, facing, power_scale, false)


func _begin_attack(
	direction: String,
	facing: float,
	power_scale: float,
	from_combo: bool
) -> bool:
	var player: Node = get_parent()
	var stamina: Node = player.get_node_or_null("StaminaComponent")
	if stamina != null:
		if not bool(stamina.call("spend", float(stamina.get("sword_cost")))):
			return false

	_attacking = true
	_elapsed = 0.0
	_direction = direction
	_attack_facing = 1.0 if facing >= 0.0 else -1.0
	_power_scale = maxf(power_scale, 1.0)
	if direction != "forward":
		_combo_step = 0
	elif not from_combo:
		_combo_step = 0
	_hit_targets.clear()
	attack_started.emit()
	return true


func physics_tick(owner_body: CharacterBody2D, _facing_direction: float, delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if not _attacking:
		return

	_elapsed += delta
	_update_hitbox_position()

	if _elapsed >= active_start and _elapsed <= active_end:
		_check_hits(owner_body)

	if _elapsed >= attack_duration:
		_finish_attack()


func _update_hitbox_position() -> void:
	match _direction:
		"up":
			hitbox.position = Vector2(0.0, -100.0)
			_query_shape.size = vertical_hitbox_size
		"down":
			hitbox.position = Vector2(0.0, 84.0)
			_query_shape.size = Vector2(vertical_hitbox_size.x, 154.0)
		_:
			var progress: float = clampf(
				(_elapsed - active_start) / maxf(active_end - active_start, 0.001),
				0.0,
				1.0
			)
			var center_x: float = lerpf(42.0, 72.0, progress)
			hitbox.position = Vector2(center_x * _attack_facing, -18.0)
			_query_shape.size = forward_hitbox_size


func _check_hits(owner_body: CharacterBody2D) -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _query_shape
	query.transform = Transform2D(0.0, owner_body.to_global(hitbox.position))
	query.collision_mask = enemy_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [owner_body.get_rid()]

	var results: Array[Dictionary] = owner_body.get_world_2d().direct_space_state.intersect_shape(query, 40)
	for result: Dictionary in results:
		var target: Node = result.get("collider") as Node
		if (
			target == null
			or target == owner_body
			or _hit_targets.has(target)
			or not target.has_method("take_hit")
		):
			continue

		_hit_targets.append(target)
		var actual_damage: int = maxi(1, roundi(float(damage) * _power_scale))
		target.call("take_hit", actual_damage, _calculate_knockback())
		hit_landed.emit(target)

		if _direction == "down" and not owner_body.is_on_floor():
			owner_body.velocity.y = pogo_velocity

		if debug_hits:
			print("[Mountain Blade] Hit ", target.name)


func _calculate_knockback() -> Vector2:
	match _direction:
		"up":
			return Vector2(0.0, -knockback_force)
		"down":
			return Vector2(0.0, knockback_force)
		_:
			return Vector2(_attack_facing * knockback_force, -100.0)


func is_attacking() -> bool:
	return _attacking


func attack_direction() -> String:
	return _direction


func combo_step() -> int:
	return _combo_step


func attack_progress() -> float:
	if not _attacking:
		return 0.0
	return clampf(_elapsed / maxf(attack_duration, 0.001), 0.0, 1.0)


func is_attack_active() -> bool:
	return _attacking and _elapsed >= active_start and _elapsed <= active_end


func _finish_attack() -> void:
	var chain_attack: bool = _buffered_attack and _direction == "forward"
	var next_direction: String = _buffered_direction
	var next_facing: float = _buffered_facing

	_attacking = false
	_elapsed = 0.0
	_power_scale = 1.0
	_hit_targets.clear()
	_buffered_attack = false
	attack_finished.emit()

	if chain_attack:
		_combo_step = 1 - _combo_step
		if _begin_attack(next_direction, next_facing, 1.0, true):
			return

	_combo_step = 0
	_cooldown_remaining = attack_cooldown


func cancel_attack() -> void:
	if not _attacking:
		return
	_buffered_attack = false
	_attacking = false
	_elapsed = 0.0
	_combo_step = 0
	_hit_targets.clear()
	_cooldown_remaining = attack_cooldown
	attack_finished.emit()
