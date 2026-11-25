extends CharacterBody2D

## Higher-quality reusable Jvari combatant.
## Each archetype now has its own combat identity:
## - sentry: disciplined shield guard + measured counter thrust
## - raider: fast pressure, backstep evade, two-hit pressure at higher difficulty
## - wraith: floating pursuit + brief phase evade before countering
## - warden: heavy shield, large guard meter, slow punishing counter
##
## Damage is only dealt during committed attack windows. Combatants use a
## collision exception with Xizane so they do not physically shove him around.

@export_enum("sentry", "raider", "wraith", "warden") var archetype: String = "sentry"
@export_range(0, 4, 1) var difficulty: int = 0

@export_group("Detection")
@export var detection_range: float = 480.0
@export var lose_range: float = 760.0
@export var vertical_tolerance: float = 150.0

@export_group("Movement")
@export var patrol_speed: float = 58.0
@export var approach_speed: float = 110.0
@export var acceleration: float = 760.0
@export var gravity: float = 1500.0
@export var patrol_radius: float = 150.0
@export_flags_2d_physics var terrain_collision_mask: int = 1
@export var ledge_check_distance: float = 38.0
@export var ledge_check_depth: float = 120.0

@export_group("Combat")
@export var attack_damage: int = 10
@export var attack_range: float = 86.0
@export var attack_reach: float = 112.0
@export var attack_height: float = 82.0
@export var attack_cooldown: float = 0.82
@export var windup_duration: float = 0.34
@export var strike_duration: float = 0.20
@export var recovery_duration: float = 0.42
@export var lunge_speed: float = 210.0
@export var attack_poise_damage: float = 24.0

@export_group("Defense")
@export var max_guard: float = 45.0
@export var guard_recovery_per_second: float = 10.0
@export var guard_recovery_delay: float = 1.05
@export var guard_chip_multiplier: float = 0.14
@export var guard_duration: float = 0.54
@export var guard_break_duration: float = 0.78
@export var defense_cooldown: float = 0.78
@export var backstep_speed: float = 300.0
@export var backstep_duration: float = 0.23
@export var phase_speed: float = 250.0
@export var phase_duration: float = 0.27

@export_group("Health & Poise")
@export var max_health: int = 40
@export var max_poise: float = 24.0
@export var poise_recovery_per_second: float = 13.0
@export var poise_recovery_delay: float = 1.15

const PHASE_PATROL := "patrol"
const PHASE_APPROACH := "approach"
const PHASE_GUARD := "guard"
const PHASE_BACKSTEP := "backstep"
const PHASE_PHASESTEP := "phasestep"
const PHASE_WINDUP := "windup"
const PHASE_STRIKE := "strike"
const PHASE_RECOVERY := "recovery"
const PHASE_HURT := "hurt"
const PHASE_GUARD_BROKEN := "guard_broken"
const PHASE_DEAD := "dead"

var health: int = 1
var poise: float = 1.0
var guard_meter: float = 0.0
var facing: int = -1

var _player: CharacterBody2D
var _home: Vector2
var _phase: String = PHASE_PATROL
var _phase_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _defense_cooldown_timer: float = 0.0
var _guard_recovery_delay_timer: float = 0.0
var _poise_recovery_delay_timer: float = 0.0
var _hurt_flash_timer: float = 0.0
var _block_flash_timer: float = 0.0
var _clock: float = 0.0
var _patrol_direction: int = 1
var _hit_this_strike: bool = false
var _combo_step: int = 0
var _counter_ready: bool = false
var _attack_style: String = "normal"
var _dead: bool = false

var _ground_probe: RayCast2D
var _ahead_probe: RayCast2D


func _ready() -> void:
	_configure_archetype()
	health = max_health
	poise = max_poise
	guard_meter = max_guard
	_home = global_position
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 7.0
	collision_layer = 1
	collision_mask = 0 if archetype == "wraith" else terrain_collision_mask
	_build_collision()
	_build_terrain_probes()
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	call_deferred("_bind_player_collision_exception")
	add_to_group("jvari_enemy")
	queue_redraw()


func _configure_archetype() -> void:
	match archetype:
		"raider":
			max_health = 46 + difficulty * 8
			max_poise = 22.0 + float(difficulty) * 3.0
			attack_damage = 11 + difficulty * 2
			patrol_speed = 74.0
			approach_speed = 154.0 + float(difficulty) * 6.0
			attack_range = 82.0
			attack_reach = 119.0
			windup_duration = maxf(0.21, 0.30 - float(difficulty) * 0.018)
			strike_duration = 0.18
			recovery_duration = 0.31
			attack_cooldown = maxf(0.54, 0.72 - float(difficulty) * 0.03)
			lunge_speed = 286.0
			max_guard = 0.0
		"wraith":
			max_health = 29 + difficulty * 6
			max_poise = 16.0 + float(difficulty) * 2.0
			attack_damage = 10 + difficulty * 2
			patrol_speed = 72.0
			approach_speed = 126.0 + float(difficulty) * 6.0
			attack_range = 96.0
			attack_reach = 130.0
			attack_height = 110.0
			vertical_tolerance = 250.0
			windup_duration = 0.31
			strike_duration = 0.20
			recovery_duration = 0.37
			attack_cooldown = 0.78
			lunge_speed = 230.0
			max_guard = 0.0
		"warden":
			max_health = 126 + difficulty * 18
			max_poise = 58.0 + float(difficulty) * 6.0
			attack_damage = 17 + difficulty * 2
			patrol_speed = 38.0
			approach_speed = 70.0 + float(difficulty) * 3.0
			attack_range = 112.0
			attack_reach = 146.0
			attack_height = 100.0
			windup_duration = 0.54
			strike_duration = 0.27
			recovery_duration = 0.66
			attack_cooldown = 1.04
			lunge_speed = 168.0
			attack_poise_damage = 38.0
			max_guard = 105.0 + float(difficulty) * 12.0
			guard_recovery_per_second = 8.0
			guard_duration = 0.68
			guard_break_duration = 1.02
		_:
			max_health = 43 + difficulty * 7
			max_poise = 32.0 + float(difficulty) * 4.0
			attack_damage = 10 + difficulty * 2
			patrol_speed = 56.0
			approach_speed = 102.0 + float(difficulty) * 5.0
			attack_range = 88.0
			attack_reach = 122.0
			windup_duration = 0.37
			strike_duration = 0.21
			recovery_duration = 0.43
			attack_cooldown = 0.82
			lunge_speed = 205.0
			max_guard = 58.0 + float(difficulty) * 7.0


func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "JvariEnemyCollision"
	var shape := CapsuleShape2D.new()
	if archetype == "warden":
		shape.radius = 25.0
		shape.height = 88.0
		collision.position = Vector2(0.0, -39.0)
	else:
		shape.radius = 18.0
		shape.height = 66.0
		collision.position = Vector2(0.0, -30.0)
	collision.shape = shape
	add_child(collision)


func _build_terrain_probes() -> void:
	if archetype == "wraith":
		return
	_ground_probe = RayCast2D.new()
	_ground_probe.name = "JvariGroundProbe"
	_ground_probe.enabled = true
	_ground_probe.exclude_parent = true
	_ground_probe.collision_mask = terrain_collision_mask
	_ground_probe.target_position = Vector2(0.0, ledge_check_depth)
	add_child(_ground_probe)

	_ahead_probe = RayCast2D.new()
	_ahead_probe.name = "JvariAheadProbe"
	_ahead_probe.enabled = true
	_ahead_probe.exclude_parent = true
	_ahead_probe.collision_mask = terrain_collision_mask
	_ahead_probe.target_position = Vector2(0.0, ledge_check_depth)
	add_child(_ahead_probe)


func _bind_player_collision_exception() -> void:
	_get_player()
	if is_instance_valid(_player):
		add_collision_exception_with(_player)
		_player.add_collision_exception_with(self)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_clock += delta
	_phase_timer = maxf(0.0, _phase_timer - delta)
	_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)
	_defense_cooldown_timer = maxf(0.0, _defense_cooldown_timer - delta)
	_guard_recovery_delay_timer = maxf(0.0, _guard_recovery_delay_timer - delta)
	_poise_recovery_delay_timer = maxf(0.0, _poise_recovery_delay_timer - delta)
	_hurt_flash_timer = maxf(0.0, _hurt_flash_timer - delta)
	_block_flash_timer = maxf(0.0, _block_flash_timer - delta)

	if max_guard > 0.0 and _guard_recovery_delay_timer <= 0.0 and _phase != PHASE_GUARD_BROKEN:
		guard_meter = minf(max_guard, guard_meter + guard_recovery_per_second * delta)
	if _poise_recovery_delay_timer <= 0.0:
		poise = minf(max_poise, poise + poise_recovery_per_second * delta)

	_get_player()
	var offset := Vector2(99999.0, 99999.0)
	if is_instance_valid(_player):
		offset = _player.global_position - global_position
		if absf(offset.x) > 8.0 and _phase not in [PHASE_STRIKE, PHASE_BACKSTEP, PHASE_PHASESTEP]:
			facing = 1 if offset.x > 0.0 else -1

	if archetype != "wraith" and not is_on_floor():
		velocity.y = minf(980.0, velocity.y + gravity * delta)

	match _phase:
		PHASE_PATROL:
			_process_patrol(delta, offset)
		PHASE_APPROACH:
			_process_approach(delta, offset)
		PHASE_GUARD:
			_process_guard(delta, offset)
		PHASE_BACKSTEP:
			_process_backstep(delta, offset)
		PHASE_PHASESTEP:
			_process_phasestep(delta, offset)
		PHASE_WINDUP:
			_process_windup(delta, offset)
		PHASE_STRIKE:
			_process_strike(delta, offset)
		PHASE_RECOVERY:
			_process_recovery(delta, offset)
		PHASE_HURT, PHASE_GUARD_BROKEN:
			_process_stagger(delta, offset)

	move_and_slide()
	queue_redraw()


func _process_patrol(delta: float, offset: Vector2) -> void:
	if _player_detected(offset):
		_enter_phase(PHASE_APPROACH)
		return

	if archetype == "wraith":
		var hover_target := _home + Vector2(sin(_clock * 0.75) * 130.0, cos(_clock * 1.35) * 30.0)
		velocity = velocity.move_toward((hover_target - global_position).normalized() * patrol_speed, 380.0 * delta)
		return

	if global_position.x > _home.x + patrol_radius:
		_patrol_direction = -1
	elif global_position.x < _home.x - patrol_radius:
		_patrol_direction = 1
	if _would_walk_off_edge(_patrol_direction):
		_patrol_direction *= -1
	velocity.x = move_toward(velocity.x, float(_patrol_direction) * patrol_speed, acceleration * delta)
	facing = _patrol_direction


func _process_approach(delta: float, offset: Vector2) -> void:
	if not _player_detected(offset, true):
		_enter_phase(PHASE_PATROL)
		return

	if _should_defend(offset):
		match archetype:
			"sentry", "warden":
				if guard_meter > maxf(8.0, max_guard * 0.10):
					_defense_cooldown_timer = defense_cooldown
					_enter_phase(PHASE_GUARD, guard_duration)
					return
			"raider":
				_defense_cooldown_timer = defense_cooldown + 0.22
				_counter_ready = true
				_enter_phase(PHASE_BACKSTEP, backstep_duration)
				return
			"wraith":
				_defense_cooldown_timer = defense_cooldown + 0.34
				_counter_ready = true
				_enter_phase(PHASE_PHASESTEP, phase_duration)
				return

	var distance_x := absf(offset.x)
	if distance_x <= attack_range and absf(offset.y) <= attack_height and _attack_cooldown_timer <= 0.0:
		_combo_step = 0
		_attack_style = "counter" if _counter_ready else "normal"
		var windup := windup_duration * (0.74 if _counter_ready else 1.0)
		_counter_ready = false
		_enter_phase(PHASE_WINDUP, windup)
		return

	if archetype == "wraith":
		var desired := Vector2(float(facing) * approach_speed, clampf(offset.y * 1.8, -110.0, 110.0))
		if distance_x < 70.0:
			desired.x *= -0.35
		velocity = velocity.move_toward(desired, 620.0 * delta)
		return

	var desired_speed := 0.0
	if distance_x > attack_range * 0.84:
		desired_speed = float(facing) * approach_speed
	elif distance_x < 54.0:
		desired_speed = -float(facing) * approach_speed * 0.32
	var direction := 1 if desired_speed > 0.0 else -1
	if absf(desired_speed) > 1.0 and _would_walk_off_edge(direction):
		desired_speed = 0.0
	velocity.x = move_toward(velocity.x, desired_speed, acceleration * delta)


func _process_guard(delta: float, offset: Vector2) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.1 * delta)
	if absf(offset.x) > 8.0:
		facing = 1 if offset.x > 0.0 else -1
	if _phase_timer <= 0.0:
		if absf(offset.x) <= attack_range + 24.0 and _attack_cooldown_timer <= 0.0:
			_counter_ready = true
			_attack_style = "counter"
			_enter_phase(PHASE_WINDUP, windup_duration * (0.70 if archetype == "sentry" else 0.82))
		else:
			_enter_phase(PHASE_APPROACH)


func _process_backstep(_delta: float, offset: Vector2) -> void:
	velocity.x = -float(facing) * backstep_speed
	if _phase_timer <= 0.0:
		if absf(offset.x) <= attack_range + 60.0 and _attack_cooldown_timer <= 0.0:
			_attack_style = "counter"
			_enter_phase(PHASE_WINDUP, windup_duration * 0.68)
		else:
			_enter_phase(PHASE_APPROACH)


func _process_phasestep(delta: float, offset: Vector2) -> void:
	var drift := Vector2(-float(facing) * phase_speed, -42.0 + sin(_clock * 12.0) * 18.0)
	velocity = velocity.move_toward(drift, 980.0 * delta)
	if _phase_timer <= 0.0:
		if absf(offset.x) <= attack_range + 72.0 and _attack_cooldown_timer <= 0.0:
			_attack_style = "counter"
			_enter_phase(PHASE_WINDUP, windup_duration * 0.72)
		else:
			_enter_phase(PHASE_APPROACH)


func _process_windup(delta: float, offset: Vector2) -> void:
	if archetype == "wraith":
		velocity = velocity.move_toward(Vector2.ZERO, 880.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
	if absf(offset.x) > 10.0:
		facing = 1 if offset.x > 0.0 else -1
	if _phase_timer <= 0.0:
		_hit_this_strike = false
		_enter_phase(PHASE_STRIKE, strike_duration)
		var style_scale := 1.10 if _attack_style == "counter" else 1.0
		velocity.x = float(facing) * lunge_speed * style_scale


func _process_strike(delta: float, offset: Vector2) -> void:
	_try_strike(offset)
	if archetype == "wraith":
		velocity = velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 0.78 * delta)

	if _phase_timer > 0.0:
		return

	if (
		archetype == "raider"
		and _combo_step == 0
		and difficulty >= 1
		and absf(offset.x) <= attack_range + 30.0
		and absf(offset.y) <= attack_height
	):
		_combo_step = 1
		_attack_style = "combo2"
		_enter_phase(PHASE_WINDUP, 0.16)
		return

	_attack_cooldown_timer = attack_cooldown
	var extra_recovery := 0.15 if archetype == "warden" else 0.0
	_enter_phase(PHASE_RECOVERY, recovery_duration + extra_recovery)


func _process_recovery(delta: float, offset: Vector2) -> void:
	if archetype == "wraith":
		velocity = velocity.move_toward(Vector2.ZERO, 620.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 1.6 * delta)
	if _phase_timer <= 0.0:
		_enter_phase(PHASE_APPROACH if _player_detected(offset, true) else PHASE_PATROL)


func _process_stagger(delta: float, offset: Vector2) -> void:
	if archetype == "wraith":
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 1.35 * delta)
	if _phase_timer <= 0.0:
		_enter_phase(PHASE_APPROACH if _player_detected(offset, true) else PHASE_PATROL)


func _try_strike(offset: Vector2) -> void:
	if _hit_this_strike or not is_instance_valid(_player) or not _player.has_method("receive_enemy_hit"):
		return
	var forward_distance := offset.x * float(facing)
	var reach := attack_reach
	if _attack_style == "counter":
		reach += 12.0
	elif _attack_style == "combo2":
		reach += 8.0
	if forward_distance < -18.0 or forward_distance > reach:
		return
	if absf(offset.y) > attack_height:
		return
	_hit_this_strike = true
	var dealt_damage := attack_damage
	var dealt_poise := attack_poise_damage
	if _attack_style == "counter":
		dealt_damage += 2 if archetype != "warden" else 3
		dealt_poise += 5.0 if archetype != "warden" else 10.0
	elif _attack_style == "combo2":
		dealt_damage = maxi(1, attack_damage - 2)
	_player.call("receive_enemy_hit", dealt_damage, global_position, dealt_poise)


func _should_defend(offset: Vector2) -> bool:
	if _defense_cooldown_timer > 0.0 or absf(offset.x) > 155.0 or absf(offset.y) > 105.0:
		return false
	if archetype == "warden" and _phase == PHASE_GUARD_BROKEN:
		return false
	var combat := _player_combat()
	if combat == null or not combat.has_method("is_attacking") or not bool(combat.call("is_attacking")):
		return false
	if combat.has_method("attack_progress"):
		var progress := float(combat.call("attack_progress"))
		return progress >= 0.02 and progress <= 0.60
	return true


func _player_combat() -> Node:
	if not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("SwordCombatComponent")


func _player_detected(offset: Vector2, use_lose_range: bool = false) -> bool:
	if not is_instance_valid(_player):
		return false
	var horizontal := lose_range if use_lose_range else detection_range
	return absf(offset.x) <= horizontal and absf(offset.y) <= vertical_tolerance * (1.5 if use_lose_range else 1.0)


func _get_player() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	return is_instance_valid(_player)


func _would_walk_off_edge(direction: int) -> bool:
	if archetype == "wraith" or not is_on_floor() or _ground_probe == null or _ahead_probe == null:
		return false
	_ground_probe.position = Vector2.ZERO
	_ground_probe.target_position = Vector2(0.0, ledge_check_depth)
	_ground_probe.force_raycast_update()
	if not _ground_probe.is_colliding():
		return false
	_ahead_probe.position = Vector2(float(direction) * ledge_check_distance, 0.0)
	_ahead_probe.target_position = Vector2(0.0, ledge_check_depth)
	_ahead_probe.force_raycast_update()
	return not _ahead_probe.is_colliding()


func _enter_phase(next_phase: String, duration: float = 0.0) -> void:
	_phase = next_phase
	_phase_timer = duration
	queue_redraw()


func take_hit(amount: int, knockback: Vector2, poise_damage: float = 20.0) -> void:
	if _dead or amount <= 0:
		return

	if archetype == "wraith" and _phase == PHASE_PHASESTEP:
		_block_flash_timer = 0.12
		return

	if _can_block_hit():
		var guard_damage := float(amount) * 1.8 + poise_damage * 0.58
		guard_meter = maxf(0.0, guard_meter - guard_damage)
		_guard_recovery_delay_timer = guard_recovery_delay
		_block_flash_timer = 0.18
		var chip := maxi(1, roundi(float(amount) * guard_chip_multiplier))
		health = maxi(0, health - chip)
		if health <= 0:
			_die()
			return
		if guard_meter <= 0.0:
			guard_meter = 0.0
			_counter_ready = false
			_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.45)
			_enter_phase(PHASE_GUARD_BROKEN, guard_break_duration)
			velocity.x = knockback.x * 0.10
		else:
			_counter_ready = true
			velocity.x = 0.0
		queue_redraw()
		return

	health = maxi(0, health - amount)
	_hurt_flash_timer = 0.18
	if health <= 0:
		_die()
		return

	poise = maxf(0.0, poise - poise_damage)
	_poise_recovery_delay_timer = poise_recovery_delay
	if poise <= 0.0:
		poise = max_poise
		_counter_ready = false
		_enter_phase(PHASE_HURT, 0.34 if archetype != "warden" else 0.46)
		velocity = knockback * (0.30 if archetype != "warden" else 0.16)
	else:
		# Raiders and wraiths react visibly to ordinary hits without cancelling a committed strike.
		if _phase not in [PHASE_WINDUP, PHASE_STRIKE]:
			velocity.x = knockback.x * (0.14 if archetype == "warden" else 0.22)
	queue_redraw()


func _can_block_hit() -> bool:
	if archetype not in ["sentry", "warden"]:
		return false
	if _phase != PHASE_GUARD or guard_meter <= 0.0 or not is_instance_valid(_player):
		return false
	var to_player := _player.global_position.x - global_position.x
	return absf(to_player) <= 175.0 and signf(to_player) == signf(float(facing))


func _score_reward() -> int:
	var base := 6
	match archetype:
		"raider":
			base = 8
		"wraith":
			base = 7
		"warden":
			base = 17
	return base + difficulty


func _award_score() -> void:
	var target_player := get_tree().get_first_node_in_group("player")
	if target_player != null and target_player.has_method("add_score"):
		target_player.call("add_score", _score_reward())


func _die() -> void:
	_award_score()
	_dead = true
	_phase = PHASE_DEAD
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	var tween := create_tween()
	if archetype == "wraith":
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.30)
		tween.parallel().tween_property(self, "position:y", position.y - 44.0, 0.30)
	else:
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.38)
		tween.parallel().tween_property(self, "rotation", 0.10 * -float(facing), 0.38)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var hurt := _hurt_flash_timer > 0.0
	var blocked := _block_flash_timer > 0.0
	var guarding := _phase == PHASE_GUARD
	var windup := _phase == PHASE_WINDUP
	var striking := _phase == PHASE_STRIKE
	var scale_factor := 1.42 if archetype == "warden" else 1.0

	if archetype == "wraith":
		_draw_wraith(hurt, windup, striking)
	else:
		_draw_human(scale_factor, hurt, blocked, guarding, windup, striking)

	if health < max_health and not _dead:
		var bar_y := -116.0 if archetype == "warden" else -94.0
		var width := 76.0 if archetype == "warden" else 60.0
		var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
		draw_rect(Rect2(-width * 0.5, bar_y, width, 5.0), Color("#272b28"))
		draw_rect(Rect2(-width * 0.5, bar_y, width * ratio, 5.0), Color("#b86f55"))

	if max_guard > 0.0 and (guarding or guard_meter < max_guard - 0.5):
		var guard_y := -108.0 if archetype == "warden" else -86.0
		var guard_width := 70.0 if archetype == "warden" else 54.0
		var guard_ratio := clampf(guard_meter / maxf(max_guard, 1.0), 0.0, 1.0)
		draw_rect(Rect2(-guard_width * 0.5, guard_y, guard_width, 4.0), Color(0.16, 0.17, 0.16, 0.82))
		draw_rect(Rect2(-guard_width * 0.5, guard_y, guard_width * guard_ratio, 4.0), Color(0.75, 0.64, 0.41, 0.92))


func _scaled_points(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(point * factor)
	return result


func _draw_human(scale_factor: float, hurt: bool, blocked: bool, guarding: bool, windup: bool, striking: bool) -> void:
	var robe := Color("#485148")
	var robe_dark := Color("#303832")
	var leather := Color("#5a4432")
	var metal := Color("#a9a08a")
	var metal_dark := Color("#665f52")
	var shield := Color("#675844")
	if archetype == "raider":
		robe = Color("#665044")
		robe_dark = Color("#41352f")
		leather = Color("#7a5537")
	elif archetype == "warden":
		robe = Color("#56584f")
		robe_dark = Color("#363a34")
		shield = Color("#75674f")
		metal = Color("#b7ac92")
	if hurt:
		robe = Color("#a95f50")
		robe_dark = Color("#6d4038")
	if blocked:
		metal = Color("#e0c78e")

	# Legs and layered tunic.
	draw_colored_polygon(_scaled_points(PackedVector2Array([
		Vector2(-15.0, 14.0), Vector2(-5.0, 14.0), Vector2(-2.0, 45.0), Vector2(-10.0, 47.0)
	]), scale_factor), robe_dark)
	draw_colored_polygon(_scaled_points(PackedVector2Array([
		Vector2(4.0, 14.0), Vector2(14.0, 14.0), Vector2(11.0, 47.0), Vector2(3.0, 46.0)
	]), scale_factor), robe_dark)
	draw_colored_polygon(_scaled_points(PackedVector2Array([
		Vector2(-20.0, -38.0), Vector2(17.0, -38.0), Vector2(23.0, 10.0), Vector2(10.0, 26.0),
		Vector2(-12.0, 26.0), Vector2(-24.0, 8.0)
	]), scale_factor), robe)
	draw_line(Vector2(-17.0, -6.0) * scale_factor, Vector2(18.0, -4.0) * scale_factor, leather, 5.0 * scale_factor)

	# Head, hood/helmet and face shadow.
	draw_circle(Vector2(0.0, -50.0) * scale_factor, 13.0 * scale_factor, Color("#8d715d"))
	if archetype == "raider":
		draw_colored_polygon(_scaled_points(PackedVector2Array([
			Vector2(-16.0, -58.0), Vector2(-4.0, -70.0), Vector2(15.0, -60.0), Vector2(12.0, -48.0), Vector2(-13.0, -47.0)
		]), scale_factor), robe_dark)
		draw_line(Vector2(-11.0, -49.0) * scale_factor, Vector2(12.0, -49.0) * scale_factor, leather, 4.0 * scale_factor)
	else:
		draw_colored_polygon(_scaled_points(PackedVector2Array([
			Vector2(-17.0, -57.0), Vector2(0.0, -73.0), Vector2(18.0, -57.0), Vector2(14.0, -48.0), Vector2(-14.0, -48.0)
		]), scale_factor), metal_dark)
		draw_line(Vector2(-13.0, -51.0) * scale_factor, Vector2(13.0, -51.0) * scale_factor, metal, 3.0 * scale_factor)

	# Weapon arm changes pose by combat phase.
	var hand := Vector2(12.0 * float(facing), -22.0) * scale_factor
	var weapon_tip := Vector2(58.0 * float(facing), -17.0) * scale_factor
	if windup:
		weapon_tip = Vector2(-20.0 * float(facing), -55.0) * scale_factor
	elif striking:
		weapon_tip = Vector2((103.0 if archetype == "warden" else 92.0) * float(facing), -13.0) * scale_factor
	elif _phase == PHASE_RECOVERY:
		weapon_tip = Vector2(48.0 * float(facing), 2.0) * scale_factor
	draw_line(hand, weapon_tip, metal_dark, 6.0 * scale_factor)
	draw_line(hand + Vector2(3.0 * float(facing), -1.0), weapon_tip, metal, 2.1 * scale_factor)
	if archetype == "warden":
		draw_circle(weapon_tip, 8.0 * scale_factor, metal_dark)

	# Shield belongs to sentries/wardens and visibly rises during guard.
	if archetype in ["sentry", "warden"]:
		var shield_x := -18.0 * float(facing)
		if guarding:
			shield_x = 18.0 * float(facing)
		var shield_center := Vector2(shield_x, -18.0) * scale_factor
		var shield_radius := (20.0 if archetype == "warden" else 16.0) * scale_factor
		draw_circle(shield_center, shield_radius, shield)
		draw_arc(shield_center, shield_radius, 0.0, TAU, 24, metal, 2.8 * scale_factor)
		draw_circle(shield_center, 4.0 * scale_factor, metal)

	# Boots and small stance shadow.
	draw_line(Vector2(-13.0, 47.0) * scale_factor, Vector2(-2.0, 47.0) * scale_factor, Color("#2d2924"), 5.0 * scale_factor)
	draw_line(Vector2(2.0, 47.0) * scale_factor, Vector2(14.0, 47.0) * scale_factor, Color("#2d2924"), 5.0 * scale_factor)

	if _phase == PHASE_GUARD_BROKEN:
		draw_line(Vector2(-18.0, -82.0) * scale_factor, Vector2(-7.0, -69.0) * scale_factor, Color("#d9bb79"), 2.0)
		draw_line(Vector2(18.0, -82.0) * scale_factor, Vector2(7.0, -69.0) * scale_factor, Color("#d9bb79"), 2.0)


func _draw_wraith(hurt: bool, windup: bool, striking: bool) -> void:
	var cloak := Color(0.40, 0.48, 0.45, 0.92)
	var cloak_dark := Color(0.25, 0.33, 0.30, 0.90)
	if hurt:
		cloak = Color(0.61, 0.40, 0.36, 0.94)
	if _phase == PHASE_PHASESTEP:
		cloak.a = 0.35
		cloak_dark.a = 0.30

	var sway := sin(_clock * 3.1) * 5.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0, -24.0 + sway), Vector2(0.0, -51.0), Vector2(24.0, -24.0 - sway),
		Vector2(20.0, 16.0), Vector2(7.0, 6.0), Vector2(0.0, 23.0), Vector2(-8.0, 7.0), Vector2(-20.0, 16.0)
	]), cloak)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18.0, -25.0), Vector2(0.0, -43.0), Vector2(17.0, -24.0), Vector2(9.0, 6.0), Vector2(-9.0, 5.0)
	]), cloak_dark)
	draw_circle(Vector2(0.0, -22.0), 8.0, Color(0.835, 0.82, 0.68, cloak.a))
	draw_circle(Vector2(-3.0 * float(facing), -23.0), 2.0, Color(0.20, 0.24, 0.22, cloak.a))

	var hand := Vector2(8.0 * float(facing), -12.0)
	var tip := Vector2(52.0 * float(facing), -8.0)
	if windup:
		tip = Vector2(-16.0 * float(facing), -49.0)
	elif striking:
		tip = Vector2(96.0 * float(facing), -6.0)
	draw_line(hand, tip, Color(0.70, 0.67, 0.57, cloak.a), 4.0)

	if _phase == PHASE_PHASESTEP:
		for i in range(3):
			var ghost_x := -float(facing) * (18.0 + float(i) * 14.0)
			draw_circle(Vector2(ghost_x, -14.0 + float(i) * 3.0), 10.0 - float(i) * 2.0, Color(0.57, 0.67, 0.63, 0.10 + float(i) * 0.03))
