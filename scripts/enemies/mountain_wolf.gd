class_name MountainWolf
extends CharacterBody2D

## Fast aggressive mountain wolf.
##
## Behaviour:
## PATROL -> CHASE -> WINDUP -> BITE -> RECOVERY
##
## Important:
## - standing beside the wolf does NOT deal contact damage
## - damage only happens during BITE
## - every bite attempt has a cooldown, even if it misses
## - attacks can be interrupted only by breaking poise

enum State {
	PATROL,
	CHASE,
	WINDUP,
	BITE,
	RECOVERY,
	HURT,
	DEAD
}


# -------------------------------------------------------------------
# Attack
# -------------------------------------------------------------------

@export_group("Attack")

@export var attack_damage: int = 8

@export var attack_range: float = 96.0
@export var bite_reach: float = 128.0
@export var bite_height: float = 72.0

@export var windup_duration: float = 0.28
@export var bite_duration: float = 0.22
@export var recovery_duration: float = 0.32

@export var attack_cooldown: float = 0.65

# Wolf moves forward during the actual bite.
@export var bite_lunge_speed: float = 270.0


# -------------------------------------------------------------------
# Movement
# -------------------------------------------------------------------

@export_group("Movement")

@export var patrol_speed: float = 65.0
@export var chase_speed: float = 205.0
@export var acceleration: float = 700.0

@export var gravity: float = 1200.0

@export_group("Terrain")
# Match the terrain layer used by the working wild boar.
# Enable avoid_ledges after confirming that the wolf moves correctly.
# Disabled by default to guarantee that a misconfigured ray cannot freeze AI.
@export_flags_2d_physics var terrain_collision_mask: int = 1
@export var avoid_ledges: bool = false
@export var ledge_check_distance: float = 44.0
@export var ledge_check_depth: float = 115.0


# -------------------------------------------------------------------
# Detection
# -------------------------------------------------------------------

@export_group("Detection")

@export var detection_range: float = 620.0
@export var lose_range: float = 900.0
@export var detection_height: float = 160.0

@export var stop_distance: float = 18.0


# -------------------------------------------------------------------
# Health
# -------------------------------------------------------------------

@export_group("Health")

@export var max_health: int = 35
@export var hurt_duration: float = 0.30


# -------------------------------------------------------------------
# Poise
# -------------------------------------------------------------------

@export_group("Poise")

@export var max_poise: float = 18.0

@export var poise_recovery_delay: float = 1.4
@export var poise_recovery_per_second: float = 15.0

@export var bite_poise_damage: float = 28.0


# -------------------------------------------------------------------
# Scene references
# -------------------------------------------------------------------

@onready var visual: Node2D = $Visual
@onready var head: Node2D = $Visual/Head
@onready var lower_jaw: Node2D = $Visual/Head/LowerJaw
@onready var front_leg: Node2D = $Visual/FrontLeg
@onready var back_leg: Node2D = $Visual/BackLeg
@onready var tail: Node2D = $Visual/Tail

# Terrain probes are constructed here, just like in the working wild boar.
# We deliberately DO NOT depend on the old FloorAhead / WallAhead nodes;
# their missing hits or false wall hits previously cancelled movement.
var _ground_probe: RayCast2D
var _ahead_probe: RayCast2D


# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------

var state: State = State.PATROL

var health: int = 0

var facing: int = -1
var _visual_facing: int = -1

var player: Node2D

var dead: bool = false

var poise: float = 18.0


var _poise_delay: float = 0.0

var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _animation_time: float = 0.0
var _spawn_settle_timer: float = 0.18
var _turn_cooldown: float = 0.0
const TURN_LOCK_TIME: float = 0.28

var _bit_this_attack: bool = false

var _home_position: Vector2
var _patrol_distance: float = 160.0


# -------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------

func _ready() -> void:
	health = max_health
	poise = max_poise

	_home_position = global_position
	_visual_facing = facing
	_apply_visual_facing()

	# The working WildBoar uses layer/mask 1 for the ground.
	# Match those physics settings for the wolf in the same level.
	collision_layer = 1
	collision_mask = 1
	_build_terrain_probes()

	player = get_tree().get_first_node_in_group(
		"player"
	) as Node2D

	# Apply the initial facing/pose immediately so there is no first-frame
	# visual snap or mirrored overlap.
	_update_visual()


# -------------------------------------------------------------------
# Main loop
# -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		return

	_animation_time += delta
	_spawn_settle_timer = maxf(_spawn_settle_timer - delta, 0.0)
	_turn_cooldown = maxf(_turn_cooldown - delta, 0.0)

	_attack_timer = maxf(
		_attack_timer - delta,
		0.0
	)

	_poise_delay = maxf(
		_poise_delay - delta,
		0.0
	)

	if _poise_delay <= 0.0:
		poise = minf(
			max_poise,
			poise + poise_recovery_per_second * delta
		)

	if not is_on_floor():
		velocity.y = minf(
			velocity.y + gravity * delta,
			900.0
		)

	if _spawn_settle_timer > 0.0:
		velocity.x = 0.0
	else:
		match state:

			State.PATROL:
				_patrol(delta)

			State.CHASE:
				_chase(delta)

			State.WINDUP:
				_process_windup(delta)

			State.BITE:
				_process_bite(delta)

			State.RECOVERY:
				_process_recovery(delta)

			State.HURT:
				_process_hurt(delta)

			State.DEAD:
				return

	move_and_slide()

	_update_visual()


# -------------------------------------------------------------------
# Patrol
# -------------------------------------------------------------------

func _patrol(delta: float) -> void:
	if _can_detect_player():
		_enter_state(State.CHASE)
		_chase(delta) # No idle frame when Xizane enters detection range.
		return

	var from_home: float = global_position.x - _home_position.x
	if _turn_cooldown <= 0.0:
		if from_home >= _patrol_distance and facing > 0:
			_turn()
		elif from_home <= -_patrol_distance and facing < 0:
			_turn()

	if _would_walk_off_edge(facing):
		_turn()
		_brake(delta)
		return

	velocity.x = move_toward(
		velocity.x,
		float(facing) * patrol_speed,
		acceleration * delta
	)


# -------------------------------------------------------------------
# Chase
# -------------------------------------------------------------------

func _chase(delta: float) -> void:
	if not _get_player():
		_enter_state(State.PATROL)
		_brake(delta)
		return

	var offset: Vector2 = player.global_position - global_position

	if absf(offset.x) > lose_range or absf(offset.y) > detection_height * 2.0:
		_enter_state(State.PATROL)
		return

	# The direction of travel is always based on Xizane's current position,
	# not on the wolf's previous facing or its visual animation.
	if absf(offset.x) > 18.0:
		_set_facing(1 if offset.x > 0.0 else -1)

	if (
		absf(offset.x) <= attack_range
		and absf(offset.y) <= bite_height
		and _attack_timer <= 0.0
		and is_on_floor()
	):
		if absf(offset.x) > 8.0:
			_set_facing(1 if offset.x > 0.0 else -1)
		_brake(delta)
		_enter_state(State.WINDUP, windup_duration)
		return

	if absf(offset.x) <= stop_distance:
		_brake(delta)
		return

	var direction: int = 1 if offset.x > 0.0 else -1

	# Only a CONFIRMED ledge can stop pursuit. A ray with the wrong mask
	# or a missing floor hit must not freeze this enemy again.
	if _would_walk_off_edge(direction):
		_brake(delta)
		return

	# Walls are handled physically by move_and_slide(). Never use the
	# old WallAhead collision as an unconditional stop signal: it can
	# detect Xizane himself or nearby geometry and immobilize the wolf.
	velocity.x = move_toward(
		velocity.x,
		float(direction) * chase_speed,
		acceleration * delta
	)


# -------------------------------------------------------------------
# Attack states
# -------------------------------------------------------------------

func _process_windup(delta: float) -> void:
	# Track Xizane during the tell; direction locks when the bite begins.
	if _get_player():
		var dx: float = player.global_position.x - global_position.x
		if absf(dx) > 12.0:
			_set_facing(1 if dx > 0.0 else -1)
	_brake(delta)

	_state_timer -= delta

	if _state_timer > 0.0:
		return

	_bit_this_attack = false

	# Cooldown starts for EVERY bite attempt.
	# Previously it started only when the bite successfully hit.
	_attack_timer = attack_cooldown

	_enter_state(
		State.BITE,
		bite_duration
	)

	# Actual forward wolf lunge.
	velocity.x = (
		float(facing)
		* bite_lunge_speed
	)


func _process_bite(delta: float) -> void:
	_state_timer -= delta

	_try_bite()

	# Gradually slow the lunge instead of immediately cancelling it.
	velocity.x = move_toward(
		velocity.x,
		0.0,
		acceleration * 0.75 * delta
	)

	if _state_timer <= 0.0:
		_enter_state(
			State.RECOVERY,
			recovery_duration
		)


func _process_recovery(delta: float) -> void:
	_brake(delta)

	_state_timer -= delta

	if _state_timer <= 0.0:
		if _can_detect_player():
			_enter_state(State.CHASE)
		else:
			_enter_state(State.PATROL)


func _process_hurt(delta: float) -> void:
	_state_timer -= delta

	velocity.x = move_toward(
		velocity.x,
		0.0,
		acceleration * delta
	)

	if _state_timer <= 0.0:
		if _can_detect_player():
			_enter_state(State.CHASE)
		else:
			_enter_state(State.PATROL)


# -------------------------------------------------------------------
# Bite
# -------------------------------------------------------------------

func _try_bite() -> void:
	if _bit_this_attack:
		return

	if not _get_player():
		return

	if not player.has_method("receive_enemy_hit"):
		return

	var difference: Vector2 = player.global_position - global_position

	# Damage only in front of the wolf.
	var forward_distance: float = difference.x * float(facing)

	if forward_distance < -12.0:
		return

	if forward_distance > bite_reach:
		return

	# The player can still avoid the bite by being clearly above/below it,
	# but the vertical window is large enough to match the visible head.
	if absf(difference.y) > bite_height:
		return

	_bit_this_attack = true

	player.call(
		"receive_enemy_hit",
		attack_damage,
		global_position,
		bite_poise_damage
	)


# -------------------------------------------------------------------
# Player lookup
# -------------------------------------------------------------------

func _get_player() -> bool:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(
			"player"
		) as Node2D

	return is_instance_valid(player)


func _can_detect_player() -> bool:
	if not _get_player():
		return false

	var difference: Vector2 = (
		player.global_position
		- global_position
	)

	return (
		absf(difference.x) <= detection_range
		and
		absf(difference.y) <= detection_height
	)


# -------------------------------------------------------------------
# Terrain awareness
# -------------------------------------------------------------------

func _build_terrain_probes() -> void:
	_ground_probe = RayCast2D.new()
	_ground_probe.name = "WolfGroundProbe"
	_ground_probe.enabled = true
	_ground_probe.exclude_parent = true
	_ground_probe.collision_mask = terrain_collision_mask
	_ground_probe.target_position = Vector2(0.0, ledge_check_depth)
	add_child(_ground_probe)

	_ahead_probe = RayCast2D.new()
	_ahead_probe.name = "WolfAheadProbe"
	_ahead_probe.enabled = true
	_ahead_probe.exclude_parent = true
	_ahead_probe.collision_mask = terrain_collision_mask
	_ahead_probe.target_position = Vector2(0.0, ledge_check_depth)
	add_child(_ahead_probe)


func _would_walk_off_edge(direction: int) -> bool:
	if not avoid_ledges or not is_on_floor():
		return false

	# First verify that this collision layer actually detects the floor.
	# If it does not, fail OPEN so the wolf can still patrol and chase.
	_ground_probe.position = Vector2.ZERO
	_ground_probe.target_position = Vector2(0.0, ledge_check_depth)
	_ground_probe.force_raycast_update()
	if not _ground_probe.is_colliding():
		return false

	_ahead_probe.position = Vector2(float(direction) * ledge_check_distance, 0.0)
	_ahead_probe.target_position = Vector2(0.0, ledge_check_depth)
	_ahead_probe.force_raycast_update()
	return not _ahead_probe.is_colliding()


func _turn() -> void:
	if _turn_cooldown > 0.0:
		return

	_turn_cooldown = TURN_LOCK_TIME
	_set_facing(-facing)


func _set_facing(
	next_facing: int
) -> void:
	next_facing = (
		1
		if next_facing >= 0
		else -1
	)

	if facing == next_facing:
		return

	facing = next_facing
	_visual_facing = next_facing
	_apply_visual_facing()



func _apply_visual_facing() -> void:
	if visual == null:
		return
	# Set basis directly, avoiding Godot's negative-scale decomposition.
	# Keep the scene's intended Visual offset (0, -4).
	visual.transform = Transform2D(
		Vector2(float(_visual_facing), 0.0),
		Vector2(0.0, 1.0),
		Vector2(0.0, -4.0)
	)




# -------------------------------------------------------------------
# State helper
# -------------------------------------------------------------------

func _enter_state(
	next: State,
	duration: float = 0.0
) -> void:
	state = next

	_state_timer = duration

	queue_redraw()


func _brake(delta: float) -> void:
	velocity.x = move_toward(
		velocity.x,
		0.0,
		acceleration * 1.8 * delta
	)


# -------------------------------------------------------------------
# Visual state
# -------------------------------------------------------------------

func _update_visual() -> void:
	if visual == null:
		return

	# Do not write a negative Node2D scale here. In Godot, negative X
	# scale can decompose into a 180-degree rotation plus negative Y scale.
	# Mirroring is applied once, only on an actual facing change.

	var movement_amount: float = 0.0

	if _spawn_settle_timer <= 0.0:
		movement_amount = clampf(
			absf(velocity.x) / maxf(chase_speed, 1.0),
			0.0,
			1.0
		)

	var run_cycle: float = sin(_animation_time * 10.0)

	# Neutral local pose.
	head.position = Vector2(31.0, -31.0)
	head.rotation = 0.0

	lower_jaw.rotation = 0.0
	front_leg.rotation = 0.0
	back_leg.rotation = 0.0
	tail.rotation = -0.10

	match state:
		State.PATROL:
			if movement_amount > 0.08:
				front_leg.rotation = run_cycle * 0.16 * movement_amount
				back_leg.rotation = -run_cycle * 0.16 * movement_amount
				tail.rotation = -0.10 + sin(_animation_time * 2.5) * 0.05 * movement_amount

		State.CHASE:
			if movement_amount > 0.08:
				front_leg.rotation = run_cycle * 0.38 * movement_amount
				back_leg.rotation = -run_cycle * 0.38 * movement_amount
			head.rotation = -0.05
			tail.rotation = 0.10

		State.WINDUP:
			# Small crouch: no giant swing.
			head.position = Vector2(29.0, -26.0)
			head.rotation = 0.08
			front_leg.rotation = 0.16
			back_leg.rotation = -0.14
			tail.rotation = 0.18

		State.BITE:
			# Visible bite comes from head + jaw, not a fake weapon line.
			head.position = Vector2(43.0, -28.0)
			head.rotation = -0.08
			lower_jaw.rotation = 0.36
			front_leg.rotation = -0.22
			back_leg.rotation = 0.20
			tail.rotation = 0.20

		State.RECOVERY:
			head.position = Vector2(35.0, -29.0)
			head.rotation = 0.05

		State.HURT:
			head.position = Vector2(26.0, -33.0)
			head.rotation = -0.12
			tail.rotation = -0.25

		_:
			pass

	match state:
		State.WINDUP:
			visual.modulate = Color(1.06, 0.97, 0.88)

		State.HURT:
			visual.modulate = Color(1.0, 0.45, 0.42)

		_:
			visual.modulate = Color.WHITE


# -------------------------------------------------------------------
# Warning / bite effects
# -------------------------------------------------------------------

func _draw() -> void:
	if state == State.WINDUP:
		var warning := Color(
			0.96,
			0.56,
			0.29,
			0.72
		)

		# Small ground warning only.
		draw_arc(
			Vector2(
				42.0 * float(facing),
				18.0
			),
			28.0,
			0.0,
			TAU,
			24,
			warning,
			2.5
		)


	# Same compact in-world health bar style as the other enemies.
	# It appears only after the wolf has taken damage.
	if health < max_health and not dead:
		var ratio: float = clampf(
			float(health) / float(max_health),
			0.0,
			1.0
		)

		draw_rect(
			Rect2(-30.0, -95.0, 60.0, 5.0),
			Color("#292e2a")
		)

		draw_rect(
			Rect2(-30.0, -95.0, 60.0 * ratio, 5.0),
			Color("#bc7655")
		)

# -------------------------------------------------------------------
# Damage
# -------------------------------------------------------------------

func take_hit(
	amount: int,
	knockback: Vector2,
	poise_damage: float = 20.0
) -> void:
	if dead or amount <= 0:
		return

	health = maxi(
		health - amount,
		0
	)
	queue_redraw()

	if health <= 0:
		_die()
		return

	poise = maxf(
		0.0,
		poise - poise_damage
	)

	_poise_delay = poise_recovery_delay

	# A normal hit hurts the wolf but does NOT interrupt
	# a committed attack.
	#
	# Only breaking poise interrupts it.
	if poise <= 0.0:

		poise = max_poise

		_enter_state(
			State.HURT,
			hurt_duration
		)

		_attack_timer = maxf(
			_attack_timer,
			0.35
		)

		velocity = Vector2(
			knockback.x * 0.45,
			minf(
				knockback.y,
				-60.0
			)
		)


# -------------------------------------------------------------------
# Death
# -------------------------------------------------------------------

func _die() -> void:
	dead = true

	state = State.DEAD

	velocity = Vector2.ZERO

	set_physics_process(false)

	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision != null:
		collision.set_deferred(
			"disabled",
			true
		)

	var tween: Tween = create_tween()

	tween.tween_property(
		visual,
		"modulate:a",
		0.0,
		0.45
	)

	tween.tween_callback(
		queue_free
	)
