extends "res://scripts/enemies/jvari_enemy.gd"

## Twin Warden boss variant used by Jvari's final pass arena.
## The goal is higher-quality decision making, not higher raw difficulty.
## Only one twin receives attack initiative at a time; the other controls space,
## guards, and repositions. Guard breaks create a protected punish window.

@export_range(0, 1, 1) var boss_slot: int = 0

var _boss_controller: Node
var _boss_active: bool = false
var _pattern_index: int = 0
var _held_attack_token: bool = false
var _open_window_timer: float = 0.0
var _locked_attack_facing: int = -1


func set_boss_controller(controller: Node) -> void:
	_boss_controller = controller


func set_boss_active(active: bool) -> void:
	_boss_active = active
	_open_window_timer = 0.0
	if active:
		# Start like a shielded Undead Burg fighter: protected, advancing,
		# but not permanently turtled. The shield will cycle down into openings.
		_enter_phase(PHASE_GUARD, 0.92 + float(boss_slot) * 0.14)
	else:
		_enter_phase(PHASE_PATROL)
		velocity.x = 0.0


func _configure_archetype() -> void:
	archetype = "warden"
	super._configure_archetype()

	# Two coordinated Wardens should be tactical, not damage/health sponges.
	max_health = 90
	max_poise = 46.0
	attack_damage = 13
	patrol_speed = 0.0
	approach_speed = 148.0
	acceleration = 820.0
	detection_range = 3600.0
	lose_range = 4600.0
	vertical_tolerance = 240.0
	attack_range = 116.0
	attack_reach = 148.0
	attack_height = 92.0
	windup_duration = 0.52
	strike_duration = 0.24
	recovery_duration = 0.58
	attack_cooldown = 0.72
	lunge_speed = 178.0
	attack_poise_damage = 28.0
	max_guard = 72.0
	guard_recovery_per_second = 7.0
	guard_duration = 0.82
	guard_break_duration = 1.20
	guard_chip_multiplier = 0.10
	defense_cooldown = 0.70
	patrol_radius = 0.0


func _process_patrol(delta: float, _offset: Vector2) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
	if _boss_active:
		_enter_phase(PHASE_APPROACH)


func _process_approach(delta: float, offset: Vector2) -> void:
	if not _boss_active or not is_instance_valid(_player):
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
		return

	_open_window_timer = maxf(0.0, _open_window_timer - delta)
	if absf(offset.x) > 8.0:
		facing = 1 if offset.x > 0.0 else -1

	var can_take_initiative := _controller_can_request_attack()

	# The Warden whose turn it is does not camp at support distance anymore.
	# He closes until he can actually attack, lowers the shield, and commits.
	if (
		can_take_initiative
		and absf(offset.x) <= attack_range + 18.0
		and absf(offset.y) <= attack_height
		and _attack_cooldown_timer <= 0.0
	):
		if _request_attack_token():
			var countering := _counter_ready
			_counter_ready = false
			_begin_boss_attack(countering)
			return

	# Shield-down footwork is a deliberate opening. The active Warden presses
	# close; the supporting twin holds a wider lane so the pair do not stack.
	var desired_distance := 92.0 if can_take_initiative else 178.0
	var desired_speed := 0.0
	var distance_x := absf(offset.x)
	if distance_x > desired_distance + 16.0:
		desired_speed = float(facing) * approach_speed * (1.0 if can_take_initiative else 0.72)
	elif distance_x < desired_distance - 18.0:
		desired_speed = -float(facing) * approach_speed * (0.42 if can_take_initiative else 0.56)

	var move_direction := 1 if desired_speed > 0.0 else -1
	if absf(desired_speed) > 1.0 and _would_walk_off_edge(move_direction):
		desired_speed = 0.0
	velocity.x = move_toward(velocity.x, desired_speed, acceleration * delta)

	# Do not stay open forever. After a short readable gap, raise the shield
	# and keep walking. This produces the defend/open/attack rhythm.
	if _open_window_timer <= 0.0:
		_enter_phase(PHASE_GUARD, 0.92 + float(boss_slot) * 0.12)


func _process_guard(delta: float, offset: Vector2) -> void:
	if not _boss_active or not is_instance_valid(_player):
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.0 * delta)
		return

	if absf(offset.x) > 8.0:
		facing = 1 if offset.x > 0.0 else -1

	var can_take_initiative := _controller_can_request_attack()
	var distance_x := absf(offset.x)

	# Guarding no longer means standing still. Wardens shield-walk toward Xizane.
	# The active twin closes to striking distance; the support twin pressures from
	# farther out, keeping the fight readable instead of creating a dogpile.
	var desired_distance := 102.0 if can_take_initiative else 192.0
	var guard_speed := approach_speed * (0.78 if can_take_initiative else 0.58)
	var desired_speed := 0.0
	if distance_x > desired_distance + 14.0:
		desired_speed = float(facing) * guard_speed
	elif distance_x < desired_distance - 22.0:
		desired_speed = -float(facing) * guard_speed * 0.66

	var move_direction := 1 if desired_speed > 0.0 else -1
	if absf(desired_speed) > 1.0 and _would_walk_off_edge(move_direction):
		desired_speed = 0.0
	velocity.x = move_toward(velocity.x, desired_speed, acceleration * delta)

	# Owning initiative means trying to hit the player, not merely defending.
	# A recent successful block shortens the tell slightly, but does not create
	# an instant/unavoidable counter.
	if (
		can_take_initiative
		and distance_x <= attack_range + 16.0
		and absf(offset.y) <= attack_height
		and _attack_cooldown_timer <= 0.0
		and _request_attack_token()
	):
		var countering := _counter_ready
		_counter_ready = false
		_begin_boss_attack(countering)
		return

	# Shields are strong but temporary. Periodically lower them even if Xizane
	# has not attacked, giving the player a natural opening like DS1 shield mobs.
	if _phase_timer <= 0.0:
		_open_window_timer = 0.42 if can_take_initiative else 0.34
		_enter_phase(PHASE_APPROACH)


func _begin_boss_attack(from_guard: bool) -> void:
	# Lock the direction at commitment. The base enemy tracks Xizane while moving,
	# but a committed Dark-Souls-style swing should be dodgeable by crossing behind it.
	_locked_attack_facing = facing
	_pattern_index = (_pattern_index + 1) % 3
	match _pattern_index:
		0:
			# Low sweeping cut: broad reach, low vertical window; jumping is viable.
			_attack_style = "boss_sweep"
			_enter_phase(PHASE_WINDUP, 0.52 if not from_guard else 0.44)
		1:
			# Deliberate overhead blow: shorter reach, longer warning, larger punish window.
			_attack_style = "boss_overhead"
			_enter_phase(PHASE_WINDUP, 0.66 if not from_guard else 0.56)
		_:
			# Long thrust: quicker but narrow, encouraging a dash-through or spacing response.
			_attack_style = "boss_thrust"
			_enter_phase(PHASE_WINDUP, 0.42 if not from_guard else 0.36)


func _process_windup(delta: float, _offset: Vector2) -> void:
	# The parent updates facing before dispatching this phase, so explicitly restore
	# the committed facing every frame. Crossing behind a tell now genuinely works.
	facing = _locked_attack_facing
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 2.2 * delta)
	if _phase_timer > 0.0:
		return

	_hit_this_strike = false
	var strike_time := 0.24
	var strike_speed := lunge_speed
	match _attack_style:
		"boss_sweep":
			strike_time = 0.27
			strike_speed = 164.0
		"boss_overhead":
			strike_time = 0.25
			strike_speed = 96.0
		"boss_thrust":
			strike_time = 0.21
			strike_speed = 238.0
		_:
			pass
	_enter_phase(PHASE_STRIKE, strike_time)
	velocity.x = float(facing) * strike_speed


func _process_recovery(delta: float, offset: Vector2) -> void:
	# Recovery is intentionally shield-down. After it ends there is still a small
	# open footwork window before the shield comes back up.
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 1.55 * delta)
	if _phase_timer <= 0.0:
		_open_window_timer = 0.28
		_enter_phase(PHASE_APPROACH if _player_detected(offset, true) else PHASE_PATROL)


func _process_strike(delta: float, offset: Vector2) -> void:
	var was_striking := _phase == PHASE_STRIKE
	super._process_strike(delta, offset)
	if was_striking and _phase != PHASE_STRIKE:
		_release_attack_token()


func _try_strike(offset: Vector2) -> void:
	if _hit_this_strike or not is_instance_valid(_player) or not _player.has_method("receive_enemy_hit"):
		return

	var forward_distance := offset.x * float(facing)
	var reach := attack_reach
	var height := attack_height
	var dealt_damage := attack_damage
	var dealt_poise := attack_poise_damage

	match _attack_style:
		"boss_sweep":
			reach = 158.0
			height = 62.0
			dealt_damage = 12
			dealt_poise = 23.0
		"boss_overhead":
			reach = 116.0
			height = 108.0
			dealt_damage = 15
			dealt_poise = 32.0
		"boss_thrust":
			reach = 176.0
			height = 58.0
			dealt_damage = 13
			dealt_poise = 25.0
		_:
			pass

	if forward_distance < -16.0 or forward_distance > reach:
		return
	if absf(offset.y) > height:
		return

	_hit_this_strike = true
	_player.call("receive_enemy_hit", dealt_damage, global_position, dealt_poise)


func take_hit(amount: int, knockback: Vector2, poise_damage: float = 20.0) -> void:
	var previous_phase := _phase
	super.take_hit(amount, knockback, poise_damage)

	if _dead:
		_release_attack_token()
		return

	if previous_phase in [PHASE_WINDUP, PHASE_STRIKE] and _phase not in [PHASE_WINDUP, PHASE_STRIKE]:
		_release_attack_token()

	if previous_phase != PHASE_GUARD_BROKEN and _phase == PHASE_GUARD_BROKEN:
		if is_instance_valid(_boss_controller) and _boss_controller.has_method("boss_guard_broken"):
			_boss_controller.call("boss_guard_broken", self)


func _die() -> void:
	_release_attack_token()
	if is_instance_valid(_boss_controller) and _boss_controller.has_method("boss_defeated"):
		_boss_controller.call("boss_defeated", self)
	super._die()


func _score_reward() -> int:
	# The encounter awards one clear reward after both Wardens fall.
	return 0


func _controller_can_request_attack() -> bool:
	if not is_instance_valid(_boss_controller):
		return true
	if not _boss_controller.has_method("can_boss_request_attack"):
		return true
	return bool(_boss_controller.call("can_boss_request_attack", self))


func _request_attack_token() -> bool:
	if _held_attack_token:
		return true
	if not is_instance_valid(_boss_controller) or not _boss_controller.has_method("request_boss_attack"):
		_held_attack_token = true
		return true
	_held_attack_token = bool(_boss_controller.call("request_boss_attack", self))
	return _held_attack_token


func _release_attack_token() -> void:
	if not _held_attack_token:
		return
	_held_attack_token = false
	if is_instance_valid(_boss_controller) and _boss_controller.has_method("release_boss_attack"):
		_boss_controller.call("release_boss_attack", self)


func _draw() -> void:
	super._draw()

	# Extra boss-specific telegraph. These are intentionally different so the
	# player can identify the response before the active frames begin.
	if _phase != PHASE_WINDUP:
		return

	var front := float(facing)
	match _attack_style:
		"boss_sweep":
			draw_arc(Vector2(44.0 * front, 9.0), 54.0, -1.25 if facing > 0 else 1.90, 1.25 if facing > 0 else 4.39, 22, Color(0.89, 0.57, 0.31, 0.82), 3.0)
		"boss_overhead":
			draw_line(Vector2(18.0 * front, -92.0), Vector2(18.0 * front, -42.0), Color(0.91, 0.73, 0.39, 0.88), 4.0)
			draw_circle(Vector2(18.0 * front, -98.0), 5.0, Color(0.91, 0.73, 0.39, 0.72))
		"boss_thrust":
			draw_line(Vector2(34.0 * front, -16.0), Vector2(112.0 * front, -16.0), Color(0.82, 0.72, 0.49, 0.82), 2.5)
