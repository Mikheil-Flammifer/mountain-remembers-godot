class_name XizanePlayer
extends CharacterBody2D

signal healing_stones_changed(current: int)
signal shield_state_changed(active: bool)
signal score_changed(current: int)
signal upgrades_changed

const LOST_SCORE_SCENE: PackedScene = preload("res://scenes/objects/lost_score_memory.tscn")

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var combat: SwordCombatComponent = $SwordCombatComponent
@onready var visual_slot: ActorVisualSlot = $VisualSlot

@export_group("Progression")
@export var vitality: int = 10
@export var health_per_vitality: int = 10

@export_group("Shield")
@export var shield_base_energy_cost: float = 12.0
@export var shield_damage_energy_scale: float = 0.52
@export var shield_knockback: float = 84.0
@export var perfect_guard_window: float = 0.13
@export var perfect_guard_cost_multiplier: float = 0.55
@export var guard_break_duration: float = 0.48
@export_range(0.0, 1.0) var guard_break_damage_multiplier: float = 0.65

@export_group("Healing Stones")
@export var healing_stone_heal: int = 30
@export var max_healing_stones: int = 5

@export_group("Poise")
@export var max_poise: float = 25.0
@export var poise_recovery_per_second: float = 18.0
@export var poise_recovery_delay: float = 1.2
@export var stagger_duration: float = 0.30

var healing_stones: int = 1
var score: int = 0
var upgrade_levels := XizaneUpgradeRules.default_levels()
var poise: float = 25.0

var _progression_store: XizaneProgressionStore
var _attack_was_pressed: bool = false
var _heal_was_pressed: bool = false
var _poise_delay: float = 0.0
var _stagger_timer: float = 0.0
var _guard_break_timer: float = 0.0
var _shield_active: bool = false
var _shield_hold_time: float = 0.0
var _shield_flash_timer: float = 0.0
var _perfect_guard_flash_timer: float = 0.0
var _heal_flash_timer: float = 0.0
var _visual_state := ActorVisualState.new()
var _climb_phase: float = 0.0
var _is_resting: bool = false
var _last_safe_position: Vector2 = Vector2.ZERO
var _safe_sample_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 14.0
	poise = max_poise
	_progression_store = XizaneProgressionStore.new(get_tree().root)
	healing_stones = _progression_store.get_stones(max_healing_stones)
	score = _progression_store.get_score()
	upgrade_levels = _progression_store.get_levels()
	_apply_progression_stats(true)
	_last_safe_position = global_position

	health.died.connect(_on_died)

	call_deferred("_emit_initial_inventory")
	call_deferred("_spawn_lost_score_if_needed")


func _save_progression_state() -> void:
	_progression_store.save(score, healing_stones, upgrade_levels)


func _emit_initial_inventory() -> void:
	healing_stones_changed.emit(healing_stones)
	shield_state_changed.emit(false)
	score_changed.emit(score)
	upgrades_changed.emit()


func _physics_process(delta: float) -> void:
	_update_last_safe_position(delta)
	if _is_resting:
		_set_shield_active(false)
		velocity = Vector2.ZERO
		return

	_poise_delay = maxf(0.0, _poise_delay - delta)
	_shield_flash_timer = maxf(0.0, _shield_flash_timer - delta)
	_perfect_guard_flash_timer = maxf(0.0, _perfect_guard_flash_timer - delta)
	_heal_flash_timer = maxf(0.0, _heal_flash_timer - delta)
	_guard_break_timer = maxf(0.0, _guard_break_timer - delta)

	if _shield_active:
		_shield_hold_time += delta

	if _poise_delay <= 0.0:
		poise = minf(max_poise, poise + poise_recovery_per_second * delta)

	if _stagger_timer > 0.0 or _guard_break_timer > 0.0:
		_set_shield_active(false)
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
		if not is_on_floor():
			velocity.y = minf(1000.0, velocity.y + 1800.0 * delta)
		move_and_slide()
		return

	_update_shield_input()
	_handle_healing_input()
	_handle_attack_input()

	movement.physics_tick(self, delta)
	combat.physics_tick(self, movement.facing_direction, delta)


func _process(delta: float) -> void:
	_visual_state.velocity = velocity
	_visual_state.facing_direction = movement.facing_direction
	_visual_state.run_speed = movement.run_speed
	_visual_state.is_grounded = is_on_floor()
	_visual_state.is_dashing = movement.is_dashing()
	_visual_state.is_climbing = bool(get_meta(&"climbing_ladder", false))
	_visual_state.climb_phase = _climb_phase
	_visual_state.is_attacking = combat.is_attacking()
	_visual_state.is_blocking = is_blocking()
	_visual_state.is_staggered = is_staggered()
	_visual_state.attack_progress = combat.attack_progress()
	_visual_state.attack_direction = combat.attack_direction()
	_visual_state.combo_step = combat.combo_step()
	_visual_state.is_dead = health.is_dead
	_visual_state.is_resting = is_resting()
	_visual_state.is_healing = _heal_flash_timer > 0.0
	_visual_state.is_invulnerable = health.is_invulnerable() or movement.is_dash_invulnerable()
	_visual_state.shield_flash_timer = _shield_flash_timer
	_visual_state.perfect_guard_flash_timer = _perfect_guard_flash_timer
	_visual_state.heal_flash_timer = _heal_flash_timer
	visual_slot.update_visual(_visual_state, delta)


func begin_ladder_climb() -> bool:
	if is_resting() or health.is_dead or bool(get_meta(&"climbing_ladder", false)):
		return false
	set_resting(false)
	set_meta(&"climbing_ladder", true)
	set_physics_process(false)
	return true


func set_ladder_climb_phase(phase: float) -> void:
	_climb_phase = phase


func end_ladder_climb(launch_velocity: Vector2) -> void:
	set_meta(&"climbing_ladder", false)
	_climb_phase = 0.0
	if not health.is_dead:
		velocity = launch_velocity
		set_physics_process(true)


func _update_shield_input() -> void:
	var wants_shield: bool = _shield_input_pressed()
	var attacking: bool = combat.is_attacking()
	var dashing: bool = movement.is_dashing()
	var dead: bool = health.is_dead
	var can_guard: bool = wants_shield and not attacking and not dashing and not dead
	_set_shield_active(can_guard)


func _shield_input_pressed() -> bool:
	var pressed: bool = (
		Input.is_physical_key_pressed(KEY_G)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	)
	if InputMap.has_action("block"):
		pressed = pressed or Input.is_action_pressed("block")
	return pressed


func _handle_healing_input() -> void:
	var pressed: bool = Input.is_physical_key_pressed(KEY_R)
	if InputMap.has_action("heal"):
		pressed = pressed or Input.is_action_pressed("heal")
	var just_pressed: bool = pressed and not _heal_was_pressed
	_heal_was_pressed = pressed

	if just_pressed:
		use_healing_stone()


func _handle_attack_input() -> void:
	var pressed: bool = Input.is_physical_key_pressed(KEY_H)
	if InputMap.has_action("attack"):
		pressed = pressed or Input.is_action_pressed("attack")
	var just_pressed: bool = pressed and not _attack_was_pressed
	_attack_was_pressed = pressed

	if not just_pressed:
		return

	# Pressing attack while guarding smoothly lowers the shield and attacks.
	if _shield_active:
		_set_shield_active(false)

	var dash_attack: bool = movement.is_dashing()
	if dash_attack:
		movement.cancel_dash_for_attack(self)

	var direction: String = "forward"
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction = "up"
	elif (
		not is_on_floor()
		and (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	):
		direction = "down"

	var power_scale: float = 1.0
	if dash_attack:
		power_scale = combat.dash_attack_multiplier

	combat.try_start_attack(direction, movement.facing_direction, power_scale)


func movement_speed_multiplier() -> float:
	if combat.is_attacking():
		return 0.72
	return 1.0


func level_up_vitality() -> void:
	if health.is_dead:
		return
	vitality += 1
	health.increase_max_health(health_per_vitality, true)


func set_resting(value: bool) -> void:
	if health.is_dead:
		return
	_is_resting = value
	velocity = Vector2.ZERO
	_set_shield_active(false)
	combat.cancel_attack()


func is_resting() -> bool:
	return _is_resting


func is_blocking() -> bool:
	return _shield_active


func is_staggered() -> bool:
	return _stagger_timer > 0.0 or _guard_break_timer > 0.0


func add_healing_stone(amount: int = 1) -> bool:
	return _add_healing_stones(amount)


func collect_healing_stone(pickup_id: String) -> bool:
	if pickup_id.is_empty() or has_collected_healing_stone(pickup_id):
		return false
	return _add_healing_stones(1, pickup_id)


func has_collected_healing_stone(pickup_id: String) -> bool:
	return XizaneProgressionStore.has_collected(get_tree().root, pickup_id)


func _add_healing_stones(amount: int, pickup_id: String = "") -> bool:
	if amount <= 0 or healing_stones >= max_healing_stones:
		return false
	healing_stones = mini(max_healing_stones, healing_stones + amount)
	if not pickup_id.is_empty():
		_progression_store.mark_collected(pickup_id)
	_save_progression_state()
	healing_stones_changed.emit(healing_stones)
	return true


func use_healing_stone() -> bool:
	if (
		health.is_dead
		or healing_stones <= 0
		or health.current_health >= health.max_health
		or combat.is_attacking()
		or movement.is_dashing()
		or is_staggered()
		or _shield_active
	):
		return false

	healing_stones -= 1
	health.heal(healing_stone_heal)
	_heal_flash_timer = 0.42
	healing_stones_changed.emit(healing_stones)
	_save_progression_state()
	return true


func receive_enemy_hit(
	amount: int,
	attacker_position: Vector2,
	poise_damage: float = 28.0
) -> void:
	if amount <= 0 or health.is_dead:
		return

	if movement.is_dash_invulnerable():
		return

	var damage_to_take: int = amount
	if _shield_active and _attack_is_in_front(attacker_position):
		var guard_cost: float = (shield_base_energy_cost + float(amount) * shield_damage_energy_scale) * XizaneUpgradeRules.shield_cost_multiplier(get_upgrade_level("shield"))
		var perfect_guard: bool = _shield_hold_time <= _perfect_guard_window()
		if perfect_guard:
			guard_cost *= perfect_guard_cost_multiplier

		var clean_block: bool = stamina.drain_for_guard(guard_cost)
		_shield_flash_timer = 0.18
		if perfect_guard:
			_perfect_guard_flash_timer = 0.22

		var push_direction: float = 1.0 if global_position.x >= attacker_position.x else -1.0
		# Small grounded shield recoil, normal aerial recoil preserved.
		if is_on_floor():
			velocity.x = push_direction * minf((shield_knockback * (0.55 if perfect_guard else 1.0)), 42.0)
			velocity.y = 0.0
		else:
			velocity.x = push_direction * (shield_knockback * (0.55 if perfect_guard else 1.0))
			velocity.y = minf(velocity.y, -28.0)
		if clean_block:
			return

		# The shield still softens a guard-break hit, but Xizane is staggered.
		_set_shield_active(false)
		_guard_break_timer = guard_break_duration
		_stagger_timer = maxf(_stagger_timer, guard_break_duration * 0.75)
		combat.cancel_attack()
		damage_to_take = maxi(1, roundi(float(amount) * XizaneUpgradeRules.guard_break_damage_multiplier(get_upgrade_level("shield"))))

	if not health.take_damage(damage_to_take):
		return

	poise = maxf(0.0, poise - poise_damage)
	_poise_delay = poise_recovery_delay
	if poise <= 0.0:
		poise = max_poise
		_stagger_timer = stagger_duration
		combat.cancel_attack()

	var push_direction: float = 1.0 if global_position.x >= attacker_position.x else -1.0
	# zhinvali-ledge-hit-guard-v15: grounded hit keeps Xizane on ledges.
	if is_on_floor():
		velocity.x = push_direction * 42.0
		velocity.y = 0.0
	else:
		velocity.x = push_direction * 290.0
		velocity.y = -205.0
	visual_slot.flash_damage()


func _attack_is_in_front(attacker_position: Vector2) -> bool:
	var offset_x: float = attacker_position.x - global_position.x
	if absf(offset_x) <= 18.0:
		return true
	return signf(offset_x) == signf(movement.facing_direction)


func _set_shield_active(value: bool) -> void:
	if _shield_active == value:
		return
	_shield_active = value
	if value:
		_shield_hold_time = 0.0
	else:
		_shield_hold_time = 999.0
	shield_state_changed.emit(_shield_active)


func add_score(amount: int) -> void:
	if amount <= 0:
		return
	score += amount
	_save_progression_state()
	score_changed.emit(score)


func get_score() -> int:
	return score


func get_upgrade_level(kind: String) -> int:
	return XizaneUpgradeRules.clamp_level(int(upgrade_levels.get(kind, 1)))


func get_upgrade_cost(kind: String) -> int:
	return XizaneUpgradeRules.cost_for_level(kind, get_upgrade_level(kind))


func try_purchase_upgrade(kind: String) -> bool:
	if not _is_resting or not upgrade_levels.has(kind):
		return false
	var level: int = get_upgrade_level(kind)
	var cost: int = get_upgrade_cost(kind)
	if cost < 0 or score < cost:
		return false

	score -= cost
	upgrade_levels[kind] = level + 1
	_apply_progression_stats(false)
	score_changed.emit(score)
	upgrades_changed.emit()
	_save_progression_state()
	return true


func get_upgrade_value_text(kind: String) -> String:
	return XizaneUpgradeRules.value_text(kind, get_upgrade_level(kind))


func _perfect_guard_window() -> float:
	return perfect_guard_window + float(get_upgrade_level("shield") - 1) * 0.012


func _apply_progression_stats(fill_resources: bool) -> void:
	combat.damage = XizaneUpgradeRules.blade_damage_for_level(get_upgrade_level("blade"))
	healing_stone_heal = XizaneUpgradeRules.stone_heal_for_level(get_upgrade_level("stone"))

	var old_hp_max := maxi(1, health.max_health)
	var new_hp_max := XizaneUpgradeRules.max_hp_for_level(get_upgrade_level("hp"))
	health.max_health = new_hp_max
	if fill_resources or health.current_health >= old_hp_max:
		health.current_health = new_hp_max
	else:
		health.current_health = mini(new_hp_max, health.current_health + maxi(0, new_hp_max - old_hp_max))
	health.health_changed.emit(health.current_health, new_hp_max)

	var old_energy_max := maxf(1.0, stamina.max_stamina)
	var new_energy_max := XizaneUpgradeRules.max_energy_for_level(get_upgrade_level("energy"))
	stamina.max_stamina = new_energy_max
	if fill_resources or stamina.current_stamina >= old_energy_max - 0.01:
		stamina.current_stamina = new_energy_max
	else:
		stamina.current_stamina = minf(new_energy_max, stamina.current_stamina + maxf(0.0, new_energy_max - old_energy_max))
	stamina.stamina_changed.emit(stamina.current_stamina, new_energy_max)


func _update_last_safe_position(delta: float) -> void:
	if health.is_dead:
		return
	_safe_sample_timer = maxf(0.0, _safe_sample_timer - delta)
	if _safe_sample_timer > 0.0:
		return
	if is_on_floor() and absf(velocity.y) < 90.0:
		_last_safe_position = global_position
		_safe_sample_timer = 0.22


func _drop_score_on_death() -> void:
	var current_scene: Node = get_tree().current_scene
	var scene_path: String = ""
	if current_scene != null:
		scene_path = current_scene.scene_file_path

	# Dark-Souls rule: the old unrecovered drop is replaced by this death.
	# If Xizane carried zero score, the previous drop is therefore lost.
	_progression_store.set_lost_score(score, scene_path, _last_safe_position)
	score = 0
	_save_progression_state()
	score_changed.emit(0)


func _spawn_lost_score_if_needed() -> void:
	await get_tree().process_frame
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var amount := _progression_store.get_lost_amount()
	if amount <= 0 or _progression_store.get_lost_scene() != current_scene.scene_file_path:
		return
	if not get_tree().get_nodes_in_group("lost_score_memory").is_empty():
		return

	var memory := LOST_SCORE_SCENE.instantiate() as Area2D
	if memory == null:
		return
	current_scene.add_child(memory)
	memory.global_position = _progression_store.get_lost_position(global_position)
	if memory.has_method("setup"):
		memory.call("setup", amount)


func recover_lost_score() -> int:
	var amount := _progression_store.get_lost_amount()
	if amount <= 0:
		return 0
	_progression_store.set_lost_score(0)
	add_score(amount)
	return amount


func _on_died() -> void:
	_drop_score_on_death()
	_set_shield_active(false)
	set_physics_process(false)
	velocity = Vector2.ZERO
	print("[Xizane] Defeated")
