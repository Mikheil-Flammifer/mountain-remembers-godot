class_name XizanePlayer
extends CharacterBody2D

signal healing_stones_changed(current: int)
signal shield_state_changed(active: bool)
signal score_changed(current: int)
signal upgrades_changed

const META_STONES: String = "xizane_healing_stones"
const META_COLLECTED_STONES: String = "xizane_collected_healing_stones"
const META_SCORE: String = "xizane_score"
const META_UPGRADES: String = "xizane_upgrade_levels"
const META_LOST_SCORE: String = "xizane_lost_score"
const META_LOST_SCENE: String = "xizane_lost_score_scene"
const META_LOST_POSITION: String = "xizane_lost_score_position"
const META_PROGRESS_LOADED: String = "xizane_progression_loaded"
const PROGRESSION_SAVE_PATH: String = "user://xizane_progression.json"
const LOST_SCORE_SCENE: PackedScene = preload("res://scenes/objects/lost_score_memory.tscn")

const MAX_UPGRADE_LEVEL: int = 5
const UPGRADE_COSTS: Dictionary = {
	"blade": [0, 90, 210, 380, 620],
	"shield": [0, 75, 180, 330, 540],
	"stone": [0, 85, 200, 360, 580],
	"hp": [0, 100, 230, 420, 680],
	"energy": [0, 95, 220, 400, 650],
}

@onready var movement: Node = $MovementComponent
@onready var health: Node = $HealthComponent
@onready var stamina: Node = $StaminaComponent
@onready var combat: Node = $SwordCombatComponent

@onready var visual_root: Node2D = $VisualRoot
@onready var torso: Node2D = $VisualRoot/TorsoRig
@onready var head: Node2D = $VisualRoot/TorsoRig/HeadRig
@onready var shield_rig: Node2D = $VisualRoot/TorsoRig/ShieldRig
@onready var back_leg: Node2D = $VisualRoot/BackLeg
@onready var front_leg: Node2D = $VisualRoot/FrontLeg
@onready var back_arm: Node2D = $VisualRoot/BackArm
@onready var front_arm: Node2D = $VisualRoot/FrontArm
@onready var sword: Node2D = $VisualRoot/FrontArm/SwordRig

@export_group("Animation")
@export var run_stride_speed: float = 0.062
@export var leg_swing_angle: float = 0.50
@export var animation_smoothing: float = 17.0

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
var upgrade_levels: Dictionary = {
	"blade": 1,
	"shield": 1,
	"stone": 1,
	"hp": 1,
	"energy": 1,
}
var poise: float = 25.0

var _stride_phase: float = 0.0
var _idle_time: float = 0.0
var _was_grounded: bool = false
var _landing_timer: float = 0.0
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
var _damage_flash_tween: Tween
var _is_resting: bool = false
var _last_safe_position: Vector2 = Vector2.ZERO
var _safe_sample_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 6.0
	poise = max_poise
	_ensure_persistent_progress_loaded()
	_load_session_inventory()
	_load_progression_state()
	_apply_progression_stats(true)
	_last_safe_position = global_position
	_improve_equipment_shapes()

	if health != null and health.has_signal("died"):
		var death_callback := Callable(self, "_on_died")
		if not health.is_connected("died", death_callback):
			health.connect("died", death_callback)

	call_deferred("_emit_initial_inventory")
	call_deferred("_spawn_lost_score_if_needed")


func _ensure_persistent_progress_loaded() -> void:
	var root: Window = get_tree().root
	if bool(root.get_meta(META_PROGRESS_LOADED, false)):
		return
	root.set_meta(META_PROGRESS_LOADED, true)

	if not FileAccess.file_exists(PROGRESSION_SAVE_PATH):
		return
	var file := FileAccess.open(PROGRESSION_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return

	var data: Dictionary = parsed
	root.set_meta(META_SCORE, maxi(0, int(data.get("score", 0))))
	root.set_meta(META_STONES, maxi(0, int(data.get("healing_stones", 1))))
	var saved_collected: Variant = data.get("collected_stones", {})
	if saved_collected is Dictionary:
		root.set_meta(META_COLLECTED_STONES, saved_collected)
	var saved_upgrades: Variant = data.get("upgrades", {})
	if saved_upgrades is Dictionary:
		root.set_meta(META_UPGRADES, saved_upgrades)

	var lost_amount: int = maxi(0, int(data.get("lost_score", 0)))
	root.set_meta(META_LOST_SCORE, lost_amount)
	root.set_meta(META_LOST_SCENE, String(data.get("lost_scene", "")))
	var position_data: Variant = data.get("lost_position", [0.0, 0.0])
	if position_data is Array and position_data.size() >= 2:
		root.set_meta(META_LOST_POSITION, Vector2(float(position_data[0]), float(position_data[1])))
	else:
		root.set_meta(META_LOST_POSITION, Vector2.ZERO)


func _save_progression_state() -> void:
	var root: Window = get_tree().root
	var lost_position: Variant = root.get_meta(META_LOST_POSITION, Vector2.ZERO)
	var lost_x: float = 0.0
	var lost_y: float = 0.0
	if lost_position is Vector2:
		lost_x = lost_position.x
		lost_y = lost_position.y

	var data: Dictionary = {
		"score": score,
		"healing_stones": healing_stones,
		"collected_stones": root.get_meta(META_COLLECTED_STONES, {}),
		"upgrades": upgrade_levels.duplicate(true),
		"lost_score": int(root.get_meta(META_LOST_SCORE, 0)),
		"lost_scene": String(root.get_meta(META_LOST_SCENE, "")),
		"lost_position": [lost_x, lost_y],
	}
	var file := FileAccess.open(PROGRESSION_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _load_session_inventory() -> void:
	var root: Window = get_tree().root
	if root.has_meta(META_STONES):
		healing_stones = clampi(int(root.get_meta(META_STONES)), 0, max_healing_stones)
	else:
		healing_stones = 1
		root.set_meta(META_STONES, healing_stones)

	if not root.has_meta(META_COLLECTED_STONES):
		root.set_meta(META_COLLECTED_STONES, {})


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

	if movement != null:
		movement.call("physics_tick", self, delta)

	if combat != null:
		combat.call(
			"physics_tick",
			self,
			float(movement.get("facing_direction")),
			delta
		)


func _process(delta: float) -> void:
	_animate_character(delta)


func _update_shield_input() -> void:
	var wants_shield: bool = _shield_input_pressed()
	var attacking: bool = combat != null and bool(combat.call("is_attacking"))
	var dashing: bool = movement != null and bool(movement.call("is_dashing"))
	var dead: bool = health != null and bool(health.get("is_dead"))
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

	if not just_pressed or combat == null or movement == null:
		return

	# Pressing attack while guarding smoothly lowers the shield and attacks.
	if _shield_active:
		_set_shield_active(false)

	var dash_attack: bool = bool(movement.call("is_dashing"))
	if dash_attack:
		movement.call("cancel_dash_for_attack", self)

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
		power_scale = float(combat.get("dash_attack_multiplier"))

	combat.call(
		"try_start_attack",
		direction,
		float(movement.get("facing_direction")),
		power_scale
	)


func movement_speed_multiplier() -> float:
	if combat != null and bool(combat.call("is_attacking")):
		return 0.72
	return 1.0


func level_up_vitality() -> void:
	if health == null or bool(health.get("is_dead")):
		return
	vitality += 1
	health.call("increase_max_health", health_per_vitality, true)


func set_resting(value: bool) -> void:
	if health != null and bool(health.get("is_dead")):
		return
	_is_resting = value
	velocity = Vector2.ZERO
	_set_shield_active(false)
	if combat != null and combat.has_method("cancel_attack"):
		combat.call("cancel_attack")


func is_resting() -> bool:
	return _is_resting


func is_blocking() -> bool:
	return _shield_active


func is_staggered() -> bool:
	return _stagger_timer > 0.0 or _guard_break_timer > 0.0


func add_healing_stone(amount: int = 1) -> bool:
	if amount <= 0 or healing_stones >= max_healing_stones:
		return false
	var previous: int = healing_stones
	healing_stones = mini(max_healing_stones, healing_stones + amount)
	get_tree().root.set_meta(META_STONES, healing_stones)
	if healing_stones != previous:
		healing_stones_changed.emit(healing_stones)
		_save_progression_state()
		return true
	return false


func collect_healing_stone(pickup_id: String) -> bool:
	if pickup_id.is_empty():
		return false
	var root: Window = get_tree().root
	var collected: Dictionary = root.get_meta(META_COLLECTED_STONES, {})
	if collected.has(pickup_id):
		return false
	if not add_healing_stone(1):
		return false
	collected[pickup_id] = true
	root.set_meta(META_COLLECTED_STONES, collected)
	_save_progression_state()
	return true


func has_collected_healing_stone(pickup_id: String) -> bool:
	var collected: Dictionary = get_tree().root.get_meta(META_COLLECTED_STONES, {})
	return collected.has(pickup_id)


func use_healing_stone() -> bool:
	if health == null or combat == null or movement == null:
		return false
	if (
		bool(health.get("is_dead"))
		or healing_stones <= 0
		or int(health.get("current_health")) >= int(health.get("max_health"))
		or bool(combat.call("is_attacking"))
		or bool(movement.call("is_dashing"))
		or is_staggered()
		or _shield_active
	):
		return false

	healing_stones -= 1
	get_tree().root.set_meta(META_STONES, healing_stones)
	health.call("heal", healing_stone_heal)
	_heal_flash_timer = 0.42
	healing_stones_changed.emit(healing_stones)
	_save_progression_state()
	return true


func receive_enemy_hit(
	amount: int,
	attacker_position: Vector2,
	poise_damage: float = 28.0
) -> void:
	if amount <= 0 or health == null or bool(health.get("is_dead")):
		return

	if movement != null and bool(movement.call("is_dash_invulnerable")):
		return

	var damage_to_take: int = amount
	if _shield_active and _attack_is_in_front(attacker_position):
		var guard_cost: float = (shield_base_energy_cost + float(amount) * shield_damage_energy_scale) * _shield_cost_multiplier()
		var perfect_guard: bool = _shield_hold_time <= _perfect_guard_window()
		if perfect_guard:
			guard_cost *= perfect_guard_cost_multiplier

		var clean_block: bool = bool(stamina.call("drain_for_guard", guard_cost))
		_shield_flash_timer = 0.18
		if perfect_guard:
			_perfect_guard_flash_timer = 0.22

		var push_direction: float = 1.0 if global_position.x >= attacker_position.x else -1.0
		velocity.x = push_direction * (shield_knockback * (0.55 if perfect_guard else 1.0))
		velocity.y = minf(velocity.y, -28.0)

		if clean_block:
			return

		# The shield still softens a guard-break hit, but Xizane is staggered.
		_set_shield_active(false)
		_guard_break_timer = guard_break_duration
		_stagger_timer = maxf(_stagger_timer, guard_break_duration * 0.75)
		if combat != null and combat.has_method("cancel_attack"):
			combat.call("cancel_attack")
		damage_to_take = maxi(1, roundi(float(amount) * _guard_break_damage_multiplier()))

	if not bool(health.call("take_damage", damage_to_take)):
		return

	poise = maxf(0.0, poise - poise_damage)
	_poise_delay = poise_recovery_delay
	if poise <= 0.0:
		poise = max_poise
		_stagger_timer = stagger_duration
		if combat != null and combat.has_method("cancel_attack"):
			combat.call("cancel_attack")

	var push_direction: float = 1.0 if global_position.x >= attacker_position.x else -1.0
	velocity.x = push_direction * 290.0
	velocity.y = -205.0
	_flash_damage()


func _attack_is_in_front(attacker_position: Vector2) -> bool:
	var offset_x: float = attacker_position.x - global_position.x
	if absf(offset_x) <= 18.0:
		return true
	return signf(offset_x) == signf(float(movement.get("facing_direction")))


func _set_shield_active(value: bool) -> void:
	if _shield_active == value:
		return
	_shield_active = value
	if value:
		_shield_hold_time = 0.0
	else:
		_shield_hold_time = 999.0
	shield_state_changed.emit(_shield_active)


func _load_progression_state() -> void:
	var root: Window = get_tree().root
	score = maxi(0, int(root.get_meta(META_SCORE, 0)))
	if not root.has_meta(META_SCORE):
		root.set_meta(META_SCORE, score)

	var saved: Variant = root.get_meta(META_UPGRADES, {})
	if saved is Dictionary:
		var saved_levels: Dictionary = saved
		for kind_variant in upgrade_levels.keys():
			var kind: String = String(kind_variant)
			upgrade_levels[kind] = clampi(int(saved_levels.get(kind, 1)), 1, MAX_UPGRADE_LEVEL)
	root.set_meta(META_UPGRADES, upgrade_levels.duplicate(true))

	if not root.has_meta(META_LOST_SCORE):
		root.set_meta(META_LOST_SCORE, 0)
	if not root.has_meta(META_LOST_SCENE):
		root.set_meta(META_LOST_SCENE, "")
	if not root.has_meta(META_LOST_POSITION):
		root.set_meta(META_LOST_POSITION, Vector2.ZERO)


func add_score(amount: int) -> void:
	if amount <= 0:
		return
	score += amount
	get_tree().root.set_meta(META_SCORE, score)
	score_changed.emit(score)
	_save_progression_state()


func get_score() -> int:
	return score


func get_upgrade_level(kind: String) -> int:
	return clampi(int(upgrade_levels.get(kind, 1)), 1, MAX_UPGRADE_LEVEL)


func get_upgrade_cost(kind: String) -> int:
	var level: int = get_upgrade_level(kind)
	if level >= MAX_UPGRADE_LEVEL or not UPGRADE_COSTS.has(kind):
		return -1
	var costs: Array = UPGRADE_COSTS[kind]
	return int(costs[level])


func try_purchase_upgrade(kind: String) -> bool:
	if not _is_resting or not upgrade_levels.has(kind):
		return false
	var level: int = get_upgrade_level(kind)
	if level >= MAX_UPGRADE_LEVEL:
		return false
	var cost: int = get_upgrade_cost(kind)
	if cost < 0 or score < cost:
		return false

	score -= cost
	upgrade_levels[kind] = level + 1
	var root: Window = get_tree().root
	root.set_meta(META_SCORE, score)
	root.set_meta(META_UPGRADES, upgrade_levels.duplicate(true))
	_apply_progression_stats(false)
	score_changed.emit(score)
	upgrades_changed.emit()
	_save_progression_state()
	return true


func get_upgrade_value_text(kind: String) -> String:
	var level: int = get_upgrade_level(kind)
	match kind:
		"blade":
			return "%d damage" % _blade_damage_for_level(level)
		"shield":
			return "%d%% guard efficiency" % roundi(100.0 / _shield_cost_multiplier())
		"stone":
			return "%d HP healed" % _stone_heal_for_level(level)
		"hp":
			return "%d max HP" % _max_hp_for_level(level)
		"energy":
			return "%d max energy" % roundi(_max_energy_for_level(level))
	return ""


func _blade_damage_for_level(level: int) -> int:
	return 8 + (clampi(level, 1, MAX_UPGRADE_LEVEL) - 1) * 2


func _stone_heal_for_level(level: int) -> int:
	return 30 + (clampi(level, 1, MAX_UPGRADE_LEVEL) - 1) * 10


func _max_hp_for_level(level: int) -> int:
	return 100 + (clampi(level, 1, MAX_UPGRADE_LEVEL) - 1) * 12


func _max_energy_for_level(level: int) -> float:
	return 100.0 + float(clampi(level, 1, MAX_UPGRADE_LEVEL) - 1) * 12.0


func _shield_cost_multiplier() -> float:
	return 1.0 - float(get_upgrade_level("shield") - 1) * 0.08


func _guard_break_damage_multiplier() -> float:
	return clampf(0.70 - float(get_upgrade_level("shield") - 1) * 0.08, 0.38, 0.70)


func _perfect_guard_window() -> float:
	return perfect_guard_window + float(get_upgrade_level("shield") - 1) * 0.012


func _apply_progression_stats(fill_resources: bool) -> void:
	if combat != null:
		combat.set("damage", _blade_damage_for_level(get_upgrade_level("blade")))
	healing_stone_heal = _stone_heal_for_level(get_upgrade_level("stone"))

	if health != null:
		var old_hp_max: int = maxi(1, int(health.get("max_health")))
		var old_hp: int = int(health.get("current_health"))
		var new_hp_max: int = _max_hp_for_level(get_upgrade_level("hp"))
		health.set("max_health", new_hp_max)
		if fill_resources or old_hp >= old_hp_max:
			health.set("current_health", new_hp_max)
		else:
			health.set("current_health", mini(new_hp_max, old_hp + maxi(0, new_hp_max - old_hp_max)))
		if health.has_signal("health_changed"):
			health.emit_signal("health_changed", int(health.get("current_health")), new_hp_max)

	if stamina != null:
		var old_energy_max: float = maxf(1.0, float(stamina.get("max_stamina")))
		var old_energy: float = float(stamina.get("current_stamina"))
		var new_energy_max: float = _max_energy_for_level(get_upgrade_level("energy"))
		stamina.set("max_stamina", new_energy_max)
		if fill_resources or old_energy >= old_energy_max - 0.01:
			stamina.set("current_stamina", new_energy_max)
		else:
			stamina.set("current_stamina", minf(new_energy_max, old_energy + maxf(0.0, new_energy_max - old_energy_max)))
		if stamina.has_signal("stamina_changed"):
			stamina.emit_signal("stamina_changed", float(stamina.get("current_stamina")), new_energy_max)


func _update_last_safe_position(delta: float) -> void:
	if health != null and bool(health.get("is_dead")):
		return
	_safe_sample_timer = maxf(0.0, _safe_sample_timer - delta)
	if _safe_sample_timer > 0.0:
		return
	if is_on_floor() and absf(velocity.y) < 90.0:
		_last_safe_position = global_position
		_safe_sample_timer = 0.22


func _drop_score_on_death() -> void:
	var root: Window = get_tree().root
	var current_scene: Node = get_tree().current_scene
	var scene_path: String = ""
	if current_scene != null:
		scene_path = current_scene.scene_file_path

	# Dark-Souls rule: the old unrecovered drop is replaced by this death.
	# If Xizane carried zero score, the previous drop is therefore lost.
	root.set_meta(META_LOST_SCORE, score)
	root.set_meta(META_LOST_SCENE, scene_path if score > 0 else "")
	root.set_meta(META_LOST_POSITION, _last_safe_position if score > 0 else Vector2.ZERO)
	score = 0
	root.set_meta(META_SCORE, 0)
	score_changed.emit(0)
	_save_progression_state()


func _spawn_lost_score_if_needed() -> void:
	await get_tree().process_frame
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var root: Window = get_tree().root
	var amount: int = maxi(0, int(root.get_meta(META_LOST_SCORE, 0)))
	var scene_path: String = String(root.get_meta(META_LOST_SCENE, ""))
	if amount <= 0 or scene_path != current_scene.scene_file_path:
		return
	if not get_tree().get_nodes_in_group("lost_score_memory").is_empty():
		return

	var memory := LOST_SCORE_SCENE.instantiate() as Area2D
	if memory == null:
		return
	current_scene.add_child(memory)
	var lost_position: Variant = root.get_meta(META_LOST_POSITION, global_position)
	if lost_position is Vector2:
		memory.global_position = lost_position
	else:
		memory.global_position = global_position
	if memory.has_method("setup"):
		memory.call("setup", amount)


func recover_lost_score() -> int:
	var root: Window = get_tree().root
	var amount: int = maxi(0, int(root.get_meta(META_LOST_SCORE, 0)))
	if amount <= 0:
		return 0
	add_score(amount)
	root.set_meta(META_LOST_SCORE, 0)
	root.set_meta(META_LOST_SCENE, "")
	root.set_meta(META_LOST_POSITION, Vector2.ZERO)
	_save_progression_state()
	return amount


func _animate_character(delta: float) -> void:
	if movement == null or combat == null:
		return

	var grounded: bool = is_on_floor()
	var dashing: bool = bool(movement.call("is_dashing"))
	var attacking: bool = bool(combat.call("is_attacking"))
	var blocking: bool = _shield_active
	var run_speed: float = maxf(float(movement.get("run_speed")), 1.0)
	var speed_ratio: float = clampf(absf(velocity.x) / run_speed, 0.0, 1.25)
	var smoothing: float = clampf(animation_smoothing * delta, 0.0, 1.0)
	_idle_time += delta

	var facing: float = float(movement.get("facing_direction"))
	var stretch_x: float = 1.0
	var stretch_y: float = 1.0
	if dashing:
		stretch_x = 1.08
		stretch_y = 0.94
	elif not grounded and absf(velocity.y) < 100.0:
		stretch_x = 0.98
		stretch_y = 1.025
	elif _landing_timer > 0.0:
		stretch_x = 1.025
		stretch_y = 0.97
	visual_root.scale.x = facing * lerpf(absf(visual_root.scale.x), stretch_x, smoothing)
	visual_root.scale.y = lerpf(visual_root.scale.y, stretch_y, smoothing)

	if grounded and speed_ratio > 0.08 and not dashing and not attacking and not blocking:
		_stride_phase += absf(velocity.x) * run_stride_speed * delta

	var stride: float = sin(_stride_phase)
	var target_front_leg: float = 0.0
	var target_back_leg: float = 0.0
	var target_front_arm: float = 0.0
	var target_back_arm: float = 0.0
	var target_torso: float = 0.0
	var target_sword: float = -0.12
	var shield_position := Vector2(-14.0, 0.0)
	var shield_rotation: float = -0.22

	if _is_resting:
		target_torso = 0.08
		target_front_leg = 1.18
		target_back_leg = 1.05
		target_front_arm = 0.35
		target_back_arm = -0.25
		target_sword = -0.35
	elif blocking:
		target_torso = -0.11
		target_front_leg = -0.12
		target_back_leg = 0.18
		target_front_arm = -0.42
		target_back_arm = -0.92
		target_sword = -0.72
		shield_position = Vector2(25.0, -5.0)
		shield_rotation = 0.06
	elif attacking:
		var pose: Array = _attack_pose_values(
			float(combat.call("attack_progress")),
			String(combat.call("attack_direction")),
			int(combat.call("combo_step"))
		)
		target_front_leg = float(pose[0])
		target_back_leg = float(pose[1])
		target_front_arm = float(pose[2])
		target_back_arm = float(pose[3])
		target_torso = float(pose[4])
		target_sword = float(pose[5])
	elif dashing:
		target_torso = 0.27
		target_front_leg = -0.58
		target_back_leg = 0.46
		target_front_arm = -0.65
		target_back_arm = 0.38
		target_sword = -0.82
	elif not grounded:
		if velocity.y < 0.0:
			target_torso = -0.08
			target_front_leg = -0.31
			target_back_leg = 0.35
			target_front_arm = -0.38
			target_back_arm = 0.23
		else:
			target_torso = 0.08
			target_front_leg = 0.27
			target_back_leg = -0.23
			target_front_arm = 0.16
			target_back_arm = -0.22
	elif speed_ratio > 0.08:
		target_front_leg = stride * leg_swing_angle
		target_back_leg = -stride * leg_swing_angle
		target_front_arm = -stride * 0.24
		target_back_arm = stride * 0.33
		target_torso = 0.07 * speed_ratio

	if grounded and not _was_grounded:
		_landing_timer = 0.12
	_was_grounded = grounded
	_landing_timer = maxf(_landing_timer - delta, 0.0)

	front_leg.rotation = lerp_angle(front_leg.rotation, target_front_leg, smoothing)
	back_leg.rotation = lerp_angle(back_leg.rotation, target_back_leg, smoothing)
	front_arm.rotation = lerp_angle(front_arm.rotation, target_front_arm, smoothing)
	back_arm.rotation = lerp_angle(back_arm.rotation, target_back_arm, smoothing)
	torso.rotation = lerp_angle(torso.rotation, target_torso, smoothing)
	sword.rotation = lerp_angle(sword.rotation, target_sword, smoothing)
	shield_rig.position = shield_rig.position.lerp(shield_position, smoothing)
	shield_rig.rotation = lerp_angle(shield_rig.rotation, shield_rotation, smoothing)
	shield_rig.z_index = 4 if blocking else -1

	var idle_bob: float = sin(_idle_time * 2.5) * 0.55
	var run_bob: float = absf(stride) * 2.0 * minf(speed_ratio, 1.0)
	var bob: float = idle_bob
	if _is_resting:
		bob = 19.0
	elif grounded and speed_ratio > 0.08 and not attacking and not blocking:
		bob = -run_bob
	elif dashing:
		bob = -1.8
	elif attacking:
		bob = -0.6

	var landing_amount: float = (_landing_timer / 0.12) if grounded else 0.0
	torso.position.y = lerpf(torso.position.y, -7.0 + bob + landing_amount * 3.0, smoothing)
	head.rotation = lerp_angle(head.rotation, -target_torso * 0.25, smoothing)

	var target_color: Color = Color.WHITE
	if _perfect_guard_flash_timer > 0.0:
		target_color = Color(1.20, 1.16, 0.86)
	elif _shield_flash_timer > 0.0:
		target_color = Color(1.10, 1.07, 0.90)
	elif _heal_flash_timer > 0.0:
		target_color = Color(0.82, 1.14, 0.91)
	elif dashing:
		target_color = Color(1.08, 1.06, 1.02)
	visual_root.modulate = visual_root.modulate.lerp(target_color, smoothing)


func _attack_pose_values(progress: float, direction: String, combo_step: int) -> Array:
	var front_leg_value: float = -0.08
	var back_leg_value: float = 0.12
	var front_arm_value: float = 0.0
	var back_arm_value: float = 0.15
	var torso_value: float = 0.0
	var sword_value: float = -0.20

	if direction == "up":
		if progress < 0.20:
			var t: float = _ease_in_out(progress / 0.20)
			front_arm_value = lerpf(-0.25, 0.55, t)
			sword_value = lerpf(-0.20, 0.15, t)
			torso_value = lerpf(0.0, 0.10, t)
		elif progress < 0.68:
			var t: float = _ease_out((progress - 0.20) / 0.48)
			front_arm_value = lerpf(0.55, -2.65, t)
			sword_value = lerpf(0.15, -0.48, t)
			torso_value = lerpf(0.10, -0.15, t)
		else:
			var t: float = _ease_in_out((progress - 0.68) / 0.32)
			front_arm_value = lerpf(-2.65, -0.18, t)
			sword_value = lerpf(-0.48, -0.16, t)
			torso_value = lerpf(-0.15, 0.0, t)
		return [front_leg_value, back_leg_value, front_arm_value, back_arm_value, torso_value, sword_value]

	if direction == "down":
		front_leg_value = -0.24
		back_leg_value = 0.31
		if progress < 0.18:
			var t: float = _ease_in_out(progress / 0.18)
			front_arm_value = lerpf(-0.35, -1.15, t)
			torso_value = lerpf(0.0, -0.08, t)
		elif progress < 0.66:
			var t: float = _ease_out((progress - 0.18) / 0.48)
			front_arm_value = lerpf(-1.15, 0.42, t)
			sword_value = lerpf(-0.35, -1.05, t)
			torso_value = lerpf(-0.08, 0.22, t)
		else:
			var t: float = _ease_in_out((progress - 0.66) / 0.34)
			front_arm_value = lerpf(0.42, -0.12, t)
			sword_value = lerpf(-1.05, -0.18, t)
			torso_value = lerpf(0.22, 0.0, t)
		return [front_leg_value, back_leg_value, front_arm_value, back_arm_value, torso_value, sword_value]

	# Natural two-swing horizontal combo. The second attack returns the blade
	# across the body instead of replaying the exact same rotation.
	if combo_step == 0:
		if progress < 0.18:
			var t: float = _ease_in_out(progress / 0.18)
			front_arm_value = lerpf(-0.20, -1.85, t)
			sword_value = lerpf(-0.15, -0.58, t)
			torso_value = lerpf(0.0, -0.10, t)
		elif progress < 0.67:
			var t: float = _ease_out((progress - 0.18) / 0.49)
			front_arm_value = lerpf(-1.85, 0.95, t)
			sword_value = lerpf(-0.58, 0.32, t)
			torso_value = lerpf(-0.10, 0.16, t)
		else:
			var t: float = _ease_in_out((progress - 0.67) / 0.33)
			front_arm_value = lerpf(0.95, -0.18, t)
			sword_value = lerpf(0.32, -0.14, t)
			torso_value = lerpf(0.16, 0.0, t)
	else:
		if progress < 0.16:
			var t: float = _ease_in_out(progress / 0.16)
			front_arm_value = lerpf(0.70, 1.12, t)
			sword_value = lerpf(0.18, 0.48, t)
			torso_value = lerpf(0.08, 0.14, t)
		elif progress < 0.66:
			var t: float = _ease_out((progress - 0.16) / 0.50)
			front_arm_value = lerpf(1.12, -1.38, t)
			sword_value = lerpf(0.48, -0.50, t)
			torso_value = lerpf(0.14, -0.13, t)
		else:
			var t: float = _ease_in_out((progress - 0.66) / 0.34)
			front_arm_value = lerpf(-1.38, -0.18, t)
			sword_value = lerpf(-0.50, -0.14, t)
			torso_value = lerpf(-0.13, 0.0, t)

	return [front_leg_value, back_leg_value, front_arm_value, back_arm_value, torso_value, sword_value]


func _ease_out(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func _ease_in_out(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _improve_equipment_shapes() -> void:
	# The hat is intentionally untouched. Only the blade and shield are refined.
	var blade := get_node_or_null("VisualRoot/FrontArm/SwordRig/Blade") as Polygon2D
	var blade_highlight := get_node_or_null("VisualRoot/FrontArm/SwordRig/BladeHighlight") as Polygon2D
	var guard := get_node_or_null("VisualRoot/FrontArm/SwordRig/Guard") as Polygon2D
	var shield_shape := get_node_or_null("VisualRoot/TorsoRig/ShieldRig/Shield") as Polygon2D
	var shield_rim := get_node_or_null("VisualRoot/TorsoRig/ShieldRig/ShieldRim") as Polygon2D
	var shield_boss := get_node_or_null("VisualRoot/TorsoRig/ShieldRig/ShieldBoss") as Polygon2D

	if blade != null:
		blade.polygon = PackedVector2Array([
			Vector2(-1,-6), Vector2(5,-6), Vector2(7,-44),
			Vector2(4,-64), Vector2(2,-70), Vector2(0,-64), Vector2(-2,-44)
		])
		blade.color = Color("#b9bec1")
	if blade_highlight != null:
		blade_highlight.polygon = PackedVector2Array([
			Vector2(1,-8), Vector2(2,-61), Vector2(4,-48), Vector2(4,-8)
		])
		blade_highlight.color = Color("#e8dfc5")
	if guard != null:
		guard.polygon = PackedVector2Array([
			Vector2(-10,-8), Vector2(13,-8), Vector2(11,-3), Vector2(-8,-3)
		])
	if shield_shape != null:
		shield_shape.polygon = PackedVector2Array([
			Vector2(0,-20), Vector2(13,-15), Vector2(18,-3), Vector2(15,12),
			Vector2(0,22), Vector2(-15,12), Vector2(-18,-3), Vector2(-13,-15)
		])
		shield_shape.color = Color("#2e2922")
	if shield_rim != null:
		shield_rim.polygon = PackedVector2Array([
			Vector2(0,-17), Vector2(10,-13), Vector2(14,-2), Vector2(11,10),
			Vector2(0,17), Vector2(-11,10), Vector2(-14,-2), Vector2(-10,-13)
		])
		shield_rim.color = Color("#6e5938")
	if shield_boss != null:
		shield_boss.polygon = PackedVector2Array([
			Vector2(0,-6), Vector2(6,0), Vector2(0,6), Vector2(-6,0)
		])
		shield_boss.color = Color("#a28b5c")

	shield_rig.scale = Vector2(1.18, 1.18)
	sword.scale = Vector2(1.04, 1.08)


func _flash_damage() -> void:
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	var visual := get_node_or_null("VisualRoot") as CanvasItem
	if visual == null:
		return

	visual.modulate = Color(1.0, 0.35, 0.35)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.23)


func _on_died() -> void:
	_drop_score_on_death()
	_set_shield_active(false)
	set_physics_process(false)
	velocity = Vector2.ZERO
	print("[Xizane] Defeated")
