class_name SwordCombatComponent
extends Node

## Wide, deliberate slash with a short active window and per-swing hit dedupe.
## H = forward; W+H = upward; airborne S+H = downward pogo.
signal attack_started
signal attack_finished
signal hit_landed(target: Node)

@export_group("Combat")
@export var damage: int = 10
@export var attack_duration: float = 0.35
@export var active_start: float = 0.075
@export var active_end: float = 0.255
@export var attack_cooldown: float = 0.12
@export var knockback_force: float = 300.0
@export var pogo_velocity: float = -440.0
@export_group("Hitbox")
@export var forward_hitbox_size: Vector2 = Vector2(76, 76)
@export var vertical_hitbox_size: Vector2 = Vector2(70, 84)
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
var _hit_targets: Array[Node] = []
var _query_shape: RectangleShape2D

func _ready() -> void:
	hitbox.monitoring = false
	hitbox.monitorable = false
	collision.disabled = true
	_query_shape = RectangleShape2D.new()
	_query_shape.size = forward_hitbox_size

func try_start_attack(direction: String = "forward", facing: float = 1.0) -> bool:
	var player: Node = get_parent()
	if player.has_method("is_staggered") and player.is_staggered():
		return false
	if _attacking or _cooldown_remaining > 0.0 or direction not in ["forward", "up", "down"]:
		return false
	var stamina: StaminaComponent = player.get_node_or_null("StaminaComponent") as StaminaComponent
	if stamina != null and not stamina.spend(stamina.sword_cost):
		return false
	_attacking = true
	_elapsed = 0.0
	_direction = direction
	_attack_facing = 1.0 if facing >= 0.0 else -1.0
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
			hitbox.position = Vector2(0.0, -61.0)
			_query_shape.size = vertical_hitbox_size
		"down":
			hitbox.position = Vector2(0.0, 61.0)
			_query_shape.size = vertical_hitbox_size
		_:
			var progress: float = clampf((_elapsed - active_start) / maxf(active_end - active_start, 0.001), 0.0, 1.0)
			# The blade starts near Xizane and sweeps outward; this lets
			# a well-timed hit interrupt the wolf before its bite lands.
			hitbox.position = Vector2(lerpf(37.0, 58.0, progress) * _attack_facing, -15.0)
			_query_shape.size = forward_hitbox_size

func _check_hits(owner_body: CharacterBody2D) -> void:
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _query_shape
	query.transform = Transform2D(0.0, owner_body.to_global(hitbox.position))
	query.collision_mask = enemy_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [owner_body.get_rid()]
	var results: Array[Dictionary] = owner_body.get_world_2d().direct_space_state.intersect_shape(query, 32)
	for result: Dictionary in results:
		var target: Node = result.get("collider") as Node
		if target == null or target == owner_body or _hit_targets.has(target) or not target.has_method("take_hit"):
			continue
		_hit_targets.append(target)
		if target is MountainWolf:
			target.call("take_hit", damage, _calculate_knockback(), 20.0)
		else:
			target.call("take_hit", damage, _calculate_knockback())
		hit_landed.emit(target)
		if _direction == "down" and not owner_body.is_on_floor():
			owner_body.velocity.y = pogo_velocity
		if debug_hits:
			print("[Sword] Hit ", target.name)

func _calculate_knockback() -> Vector2:
	match _direction:
		"up": return Vector2(0.0, -knockback_force)
		"down": return Vector2(0.0, knockback_force)
		_: return Vector2(_attack_facing * knockback_force, -90.0)

func is_attacking() -> bool:
	return _attacking

func attack_direction() -> String:
	return _direction

func attack_progress() -> float:
	return clampf(_elapsed / maxf(attack_duration, 0.001), 0.0, 1.0) if _attacking else 0.0

func _finish_attack() -> void:
	_attacking = false
	_elapsed = 0.0
	_cooldown_remaining = attack_cooldown
	_hit_targets.clear()
	attack_finished.emit()

func cancel_attack() -> void:
	if _attacking:
		_finish_attack()