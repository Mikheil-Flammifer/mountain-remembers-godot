extends CharacterBody2D

## Mtskheta-region human enemy with readable attacks and defensive counterplay.
## shield_guard: blocks frontal attacks until guard is broken.
## swordsman: evades early attacks with a backstep and can answer with a fast counter.

@export_enum("shield_guard", "swordsman") var archetype: String = "shield_guard"
@export_range(0, 3, 1) var difficulty: int = 0
@export var score_reward: int = 8

@export_group("Detection")
@export var detection_range: float = 470.0
@export var lose_range: float = 720.0
@export var vertical_tolerance: float = 130.0

@export_group("Movement")
@export var patrol_speed: float = 55.0
@export var approach_speed: float = 112.0
@export var acceleration: float = 760.0
@export var gravity: float = 1450.0
@export var patrol_radius: float = 135.0

@export_group("Combat")
@export var attack_damage: int = 10
@export var attack_range: float = 84.0
@export var attack_reach: float = 108.0
@export var attack_height: float = 82.0
@export var attack_cooldown: float = 0.82
@export var windup_duration: float = 0.34
@export var strike_duration: float = 0.20
@export var recovery_duration: float = 0.40
@export var lunge_speed: float = 215.0
@export var attack_poise_damage: float = 24.0

@export_group("Defense")
@export var max_guard: float = 48.0
@export var guard_recovery_per_second: float = 12.0
@export var guard_recovery_delay: float = 1.0
@export var guard_damage_multiplier: float = 0.18
@export var guard_duration: float = 0.52
@export var guard_break_duration: float = 0.72
@export var defense_cooldown: float = 0.82
@export var backstep_speed: float = 285.0
@export var backstep_duration: float = 0.24

@export_group("Health")
@export var max_health: int = 52
@export var max_poise: float = 28.0
@export var poise_recovery_per_second: float = 13.0
@export var poise_recovery_delay: float = 1.15

const PHASE_PATROL := "patrol"
const PHASE_APPROACH := "approach"
const PHASE_GUARD := "guard"
const PHASE_BACKSTEP := "backstep"
const PHASE_WINDUP := "windup"
const PHASE_STRIKE := "strike"
const PHASE_RECOVERY := "recovery"
const PHASE_HURT := "hurt"
const PHASE_GUARD_BROKEN := "guard_broken"
const PHASE_DEAD := "dead"

var health: int = 1
var poise: float = 1.0
var guard_meter: float = 1.0
var facing: int = -1

var _phase: String = PHASE_PATROL
var _player: CharacterBody2D
var _home: Vector2
var _patrol_direction: int = 1
var _clock: float = 0.0
var _phase_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _defense_cooldown_timer: float = 0.0
var _guard_recovery_delay_timer: float = 0.0
var _poise_recovery_delay_timer: float = 0.0
var _blocked_flash_timer: float = 0.0
var _hurt_flash_timer: float = 0.0
var _hit_this_strike: bool = false
var _combo_step: int = 0
var _counter_ready: bool = false
var _dead: bool = false


func _ready() -> void:
	_configure_archetype()
	health = max_health
	poise = max_poise
	guard_meter = max_guard
	_home = global_position
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 7.0
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	_build_collision()
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	call_deferred("_bind_player_collision_exception")
	add_to_group("mtskheta_enemy")
	queue_redraw()


func _configure_archetype() -> void:
	if archetype == "swordsman":
		max_health = 43 + difficulty * 6
		max_poise = 22.0 + float(difficulty) * 3.0
		attack_damage = 9 + difficulty
		approach_speed = 135.0 + float(difficulty) * 7.0
		windup_duration = maxf(0.23, 0.31 - float(difficulty) * 0.02)
		attack_cooldown = maxf(0.58, 0.76 - float(difficulty) * 0.04)
		max_guard = 0.0
		score_reward = 8 + difficulty
	else:
		max_health = 58 + difficulty * 8
		max_poise = 34.0 + float(difficulty) * 4.0
		attack_damage = 10 + difficulty
		approach_speed = 104.0 + float(difficulty) * 5.0
		max_guard = 52.0 + float(difficulty) * 8.0
		score_reward = 9 + difficulty


func _build_collision() -> void:
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CombatantCollision"
	shape_node.position = Vector2(0.0, -34.0)
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17.0
	capsule.height = 68.0
	shape_node.shape = capsule
	add_child(shape_node)


func _bind_player_collision_exception() -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
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
	_blocked_flash_timer = maxf(0.0, _blocked_flash_timer - delta)
	_hurt_flash_timer = maxf(0.0, _hurt_flash_timer - delta)

	if _guard_recovery_delay_timer <= 0.0 and archetype == "shield_guard":
		guard_meter = minf(max_guard, guard_meter + guard_recovery_per_second * delta)
	if _poise_recovery_delay_timer <= 0.0:
		poise = minf(max_poise, poise + poise_recovery_per_second * delta)

	if not is_on_floor():
		velocity.y = minf(980.0, velocity.y + gravity * delta)

	_get_player()
	var offset := Vector2(9999.0, 9999.0)
	if is_instance_valid(_player):
		offset = _player.global_position - global_position
		if absf(offset.x) > 8.0 and _phase not in [PHASE_STRIKE, PHASE_BACKSTEP]:
			facing = 1 if offset.x > 0.0 else -1

	match _phase:
		PHASE_PATROL:
			_process_patrol(delta, offset)
		PHASE_APPROACH:
			_process_approach(delta, offset)
		PHASE_GUARD:
			_process_guard(delta, offset)
		PHASE_BACKSTEP:
			_process_backstep(delta, offset)
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
	if global_position.x > _home.x + patrol_radius:
		_patrol_direction = -1
	elif global_position.x < _home.x - patrol_radius:
		_patrol_direction = 1
	velocity.x = move_toward(velocity.x, float(_patrol_direction) * patrol_speed, acceleration * delta)
	facing = _patrol_direction


func _process_approach(delta: float, offset: Vector2) -> void:
	if not _player_detected(offset, true):
		_enter_phase(PHASE_PATROL)
		return

	if _should_defend(offset):
		if archetype == "shield_guard" and guard_meter > 6.0:
			_defense_cooldown_timer = defense_cooldown
			_enter_phase(PHASE_GUARD, guard_duration)
		else:
			_defense_cooldown_timer = defense_cooldown + 0.28
			_counter_ready = true
			_enter_phase(PHASE_BACKSTEP, backstep_duration)
		return

	var distance_x := absf(offset.x)
	if distance_x <= attack_range and absf(offset.y) <= attack_height and _attack_cooldown_timer <= 0.0:
		_combo_step = 0
		var windup := windup_duration * (0.72 if _counter_ready else 1.0)
		_counter_ready = false
		_enter_phase(PHASE_WINDUP, windup)
		return

	var desired_speed := 0.0
	if distance_x > attack_range * 0.82:
		desired_speed = float(facing) * approach_speed
	elif distance_x < 58.0:
		desired_speed = -float(facing) * approach_speed * 0.35
	velocity.x = move_toward(velocity.x, desired_speed, acceleration * delta)


func _process_guard(delta: float, offset: Vector2) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
	if absf(offset.x) > 8.0:
		facing = 1 if offset.x > 0.0 else -1
	if _phase_timer <= 0.0:
		if absf(offset.x) <= attack_range + 16.0 and _attack_cooldown_timer <= 0.0:
			_counter_ready = true
			_enter_phase(PHASE_WINDUP, windup_duration * 0.72)
		else:
			_enter_phase(PHASE_APPROACH)


func _process_backstep(_delta: float, offset: Vector2) -> void:
	velocity.x = -float(facing) * backstep_speed
	if _phase_timer <= 0.0:
		if absf(offset.x) <= attack_range + 34.0 and _attack_cooldown_timer <= 0.0:
			_enter_phase(PHASE_WINDUP, windup_duration * 0.68)
		else:
			_enter_phase(PHASE_APPROACH)


func _process_windup(delta: float, offset: Vector2) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.2 * delta)
	if absf(offset.x) > 10.0:
		facing = 1 if offset.x > 0.0 else -1
	if _phase_timer <= 0.0:
		_hit_this_strike = false
		_enter_phase(PHASE_STRIKE, strike_duration)
		velocity.x = float(facing) * lunge_speed * (1.08 if archetype == "swordsman" else 0.92)


func _process_strike(delta: float, offset: Vector2) -> void:
	_try_attack_hit(offset)
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 0.85 * delta)
	if _phase_timer > 0.0:
		return

	if (
		archetype == "swordsman"
		and _combo_step == 0
		and difficulty >= 1
		and absf(offset.x) <= attack_range + 22.0
		and absf(offset.y) <= attack_height
	):
		_combo_step = 1
		_enter_phase(PHASE_WINDUP, 0.18)
		return

	_attack_cooldown_timer = attack_cooldown
	_enter_phase(PHASE_RECOVERY, recovery_duration + (0.08 if archetype == "shield_guard" else 0.0))


func _process_recovery(delta: float, offset: Vector2) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 1.6 * delta)
	if _phase_timer <= 0.0:
		_enter_phase(PHASE_APPROACH if _player_detected(offset, true) else PHASE_PATROL)


func _process_stagger(delta: float, offset: Vector2) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 1.35 * delta)
	if _phase_timer <= 0.0:
		_enter_phase(PHASE_APPROACH if _player_detected(offset, true) else PHASE_PATROL)


func _try_attack_hit(offset: Vector2) -> void:
	if _hit_this_strike or not is_instance_valid(_player) or not _player.has_method("receive_enemy_hit"):
		return
	var forward_distance := offset.x * float(facing)
	if forward_distance < -16.0 or forward_distance > attack_reach:
		return
	if absf(offset.y) > attack_height:
		return
	_hit_this_strike = true
	var dealt_damage := attack_damage + (1 if _combo_step == 1 else 0)
	_player.call("receive_enemy_hit", dealt_damage, global_position, attack_poise_damage)


func _should_defend(offset: Vector2) -> bool:
	if _defense_cooldown_timer > 0.0 or absf(offset.x) > 150.0 or absf(offset.y) > 95.0:
		return false
	var combat := _player_combat()
	if combat == null or not combat.has_method("is_attacking") or not bool(combat.call("is_attacking")):
		return false
	if combat.has_method("attack_progress"):
		var progress := float(combat.call("attack_progress"))
		return progress >= 0.03 and progress <= 0.58
	return true


func _player_combat() -> Node:
	if not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("SwordCombatComponent")


func _player_detected(offset: Vector2, use_lose_range: bool = false) -> bool:
	if not is_instance_valid(_player):
		return false
	var range_limit := lose_range if use_lose_range else detection_range
	return absf(offset.x) <= range_limit and absf(offset.y) <= vertical_tolerance


func _get_player() -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if is_instance_valid(_player):
			call_deferred("_bind_player_collision_exception")


func _enter_phase(next_phase: String, duration: float = 0.0) -> void:
	_phase = next_phase
	_phase_timer = duration


func take_hit(amount: int, knockback: Vector2, poise_damage: float = 20.0) -> void:
	if _dead or amount <= 0:
		return

	if archetype == "shield_guard" and _phase == PHASE_GUARD and _player_is_in_front():
		var chip_damage := maxi(1, roundi(float(amount) * guard_damage_multiplier))
		health = maxi(0, health - chip_damage)
		guard_meter = maxf(0.0, guard_meter - float(amount) * 1.65 - poise_damage * 0.45)
		_guard_recovery_delay_timer = guard_recovery_delay
		_blocked_flash_timer = 0.16
		_counter_ready = true
		if health <= 0:
			_die()
			return
		if guard_meter <= 0.0:
			_guard_recovery_delay_timer = 1.8
			_defense_cooldown_timer = 1.5
			_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.9)
			velocity = knockback * 0.16
			_enter_phase(PHASE_GUARD_BROKEN, guard_break_duration)
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
		velocity = knockback * 0.28
		_attack_cooldown_timer = maxf(_attack_cooldown_timer, 0.45)
		_enter_phase(PHASE_HURT, 0.34)
	elif _phase not in [PHASE_WINDUP, PHASE_STRIKE]:
		velocity = knockback * 0.13
		_enter_phase(PHASE_HURT, 0.17)
	queue_redraw()


func _player_is_in_front() -> bool:
	if not is_instance_valid(_player):
		return true
	var dx := _player.global_position.x - global_position.x
	if absf(dx) < 12.0:
		return true
	return (dx > 0.0 and facing > 0) or (dx < 0.0 and facing < 0)


func _die() -> void:
	if _dead:
		return
	_dead = true
	_phase = PHASE_DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	var target_player := get_tree().get_first_node_in_group("player")
	if target_player != null and target_player.has_method("add_score"):
		target_player.call("add_score", score_reward)
	var tween := create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.34)
	tween.parallel().tween_property(self, "position:y", position.y + 20.0, 0.34)
	tween.tween_callback(queue_free)


func _pt(x: float, y: float) -> Vector2:
	return Vector2(x * float(facing), y)


func _draw() -> void:
	var moving := clampf(absf(velocity.x) / maxf(approach_speed, 1.0), 0.0, 1.0)
	var step := sin(_clock * 9.0) * 5.0 * moving
	var body_col := Color("#695644") if archetype == "shield_guard" else Color("#704a3a")
	var cloak_col := Color("#403d35") if archetype == "shield_guard" else Color("#493b3a")
	var leather := Color("#5a3f2b")
	var metal := Color("#b6a37f")
	var shield_col := Color("#765f43")
	if _hurt_flash_timer > 0.0:
		body_col = Color("#b56e55")
	if _blocked_flash_timer > 0.0:
		shield_col = Color("#b58a55")

	# Ground shadow.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-25.0, 1.0), Vector2(23.0, 1.0), Vector2(17.0, 6.0), Vector2(-18.0, 6.0)
	]), Color("#201c18", 0.24))

	# Legs and boots.
	draw_line(_pt(-7.0, -25.0), _pt(-9.0 + step, -2.0), leather, 7.0)
	draw_line(_pt(7.0, -25.0), _pt(8.0 - step, -2.0), leather, 7.0)
	draw_line(_pt(-13.0 + step, -2.0), _pt(-4.0 + step, -2.0), Color("#2f2924"), 5.0)
	draw_line(_pt(4.0 - step, -2.0), _pt(14.0 - step, -2.0), Color("#2f2924"), 5.0)

	# Cloak and torso.
	draw_colored_polygon(PackedVector2Array([
		_pt(-20.0, -60.0), _pt(17.0, -60.0), _pt(23.0, -22.0), _pt(7.0, -15.0), _pt(-16.0, -20.0)
	]), cloak_col)
	draw_rect(Rect2(-14.0, -60.0, 28.0, 36.0), body_col)
	draw_line(_pt(0.0, -57.0), _pt(0.0, -25.0), Color("#8b7257", 0.65), 2.0)

	# Head / cap.
	draw_circle(_pt(0.0, -73.0), 11.0, Color("#9a795f"))
	draw_colored_polygon(PackedVector2Array([
		_pt(-12.0, -78.0), _pt(-6.0, -89.0), _pt(8.0, -87.0), _pt(13.0, -77.0)
	]), Color("#343834"))

	var sword_hand := _pt(10.0, -49.0)
	var sword_tip := _pt(42.0, -38.0)
	if _phase == PHASE_WINDUP:
		sword_hand = _pt(8.0, -54.0)
		sword_tip = _pt(-5.0, -101.0)
	elif _phase == PHASE_STRIKE:
		sword_hand = _pt(14.0, -47.0)
		sword_tip = _pt(76.0, -36.0 + float(_combo_step) * 18.0)
	elif _phase == PHASE_GUARD:
		sword_tip = _pt(6.0, -79.0)
	elif _phase == PHASE_BACKSTEP:
		sword_tip = _pt(34.0, -66.0)

	# Arm and sword.
	draw_line(_pt(7.0, -52.0), sword_hand, body_col, 6.0)
	draw_line(sword_hand, sword_tip, metal, 4.0)
	draw_line(sword_tip, sword_tip + _pt(5.0, -1.0), Color("#ded0ad"), 1.5)

	# Defensive equipment.
	if archetype == "shield_guard":
		var shield_center := _pt(22.0, -46.0)
		if _phase == PHASE_GUARD:
			shield_center = _pt(31.0, -47.0)
		draw_colored_polygon(PackedVector2Array([
			shield_center + _pt(-13.0, -20.0),
			shield_center + _pt(12.0, -16.0),
			shield_center + _pt(16.0, 8.0),
			shield_center + _pt(0.0, 22.0),
			shield_center + _pt(-15.0, 7.0)
		]), shield_col)
		draw_line(shield_center + _pt(0.0, -15.0), shield_center + _pt(0.0, 15.0), metal, 2.2)
		draw_line(shield_center + _pt(-9.0, 0.0), shield_center + _pt(10.0, 0.0), metal, 2.0)
	else:
		# Off-hand dagger / parrying knife.
		draw_line(_pt(-8.0, -51.0), _pt(-30.0, -41.0), Color("#9f8d6e"), 3.0)

	# Health and guard bars appear only after combat begins.
	if health < max_health and not _dead:
		var hp_ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
		draw_rect(Rect2(-31.0, -112.0, 62.0, 5.0), Color("#242520"))
		draw_rect(Rect2(-31.0, -112.0, 62.0 * hp_ratio, 5.0), Color("#b56d50"))
		if archetype == "shield_guard":
			var guard_ratio := clampf(guard_meter / maxf(max_guard, 1.0), 0.0, 1.0)
			draw_rect(Rect2(-31.0, -104.0, 62.0, 3.0), Color("#30291f"))
			draw_rect(Rect2(-31.0, -104.0, 62.0 * guard_ratio, 3.0), Color("#b89a5d"))
