class_name XizanePlayer
extends CharacterBody2D

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var combat: SwordCombatComponent = $SwordCombatComponent

@onready var visual_root: Node2D = $VisualRoot
@onready var torso: Node2D = $VisualRoot/TorsoRig
@onready var head: Node2D = $VisualRoot/TorsoRig/HeadRig
@onready var hat: Node2D = $VisualRoot/TorsoRig/HeadRig/HatRig

@onready var back_leg: Node2D = $VisualRoot/BackLeg
@onready var front_leg: Node2D = $VisualRoot/FrontLeg
@onready var back_arm: Node2D = $VisualRoot/BackArm
@onready var front_arm: Node2D = $VisualRoot/FrontArm
@onready var sword: Node2D = $VisualRoot/FrontArm/SwordRig

@export_group("Animation")
@export var run_stride_speed: float = 0.055
@export var leg_swing_angle: float = 0.48
@export var animation_smoothing: float = 12.0

@export_group("Progression")
@export var vitality: int = 10
@export var health_per_vitality: int = 10


var _stride_phase: float = 0.0
var _idle_time: float = 0.0
var _was_grounded: bool = false
var _landing_timer: float = 0.0
var _attack_was_pressed: bool = false
# V5_STAMINA_POISE: hit priority depends on poise, not invulnerable contact damage.
@export var max_poise: float = 25.0
@export var poise_recovery_per_second: float = 18.0
@export var poise_recovery_delay: float = 1.2
@export var stagger_duration: float = 0.30
var poise: float = 25.0
var _poise_delay: float = 0.0
var _stagger_timer: float = 0.0
var _damage_flash_tween: Tween
var _is_resting: bool = false

func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 6.0

	if not health.died.is_connected(_on_died):
		health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	if _is_resting:
		velocity = Vector2.ZERO

		if (
			Input.is_action_just_pressed("move_left")
			or Input.is_action_just_pressed("move_right")
			or Input.is_action_just_pressed("jump")
		):
			set_resting(false)

		return

	_poise_delay = maxf(0.0, _poise_delay - delta)

	if _poise_delay <= 0.0:
		poise = minf(
			max_poise,
			poise + poise_recovery_per_second * delta
		)

	if _stagger_timer > 0.0:
		_stagger_timer = maxf(
			0.0,
			_stagger_timer - delta
		)

		velocity.x = move_toward(
			velocity.x,
			0.0,
			1800.0 * delta
		)

		if not is_on_floor():
			velocity.y += 1500.0 * delta

		move_and_slide()
		return

	_handle_attack_input()

	if movement != null:
		movement.physics_tick(self, delta)

	if combat != null:
		combat.physics_tick(
			self,
			movement.facing_direction,
			delta
		)

func _process(delta: float) -> void:
	_animate_character(delta)



func _handle_attack_input() -> void:
	var h_pressed: bool = Input.is_physical_key_pressed(KEY_H)
	var just_pressed: bool = h_pressed and not _attack_was_pressed

	_attack_was_pressed = h_pressed

	if not just_pressed:
		return

	if movement.is_dashing():
		return

	var direction: String = "forward"

	if (
		Input.is_physical_key_pressed(KEY_W)
		or Input.is_physical_key_pressed(KEY_UP)
	):
		direction = "up"

	elif (
		not is_on_floor()
		and (
			Input.is_physical_key_pressed(KEY_S)
			or Input.is_physical_key_pressed(KEY_DOWN)
		)
	):
		direction = "down"

	combat.try_start_attack(
		direction,
		movement.facing_direction
	)



func level_up_vitality() -> void:
	if health.is_dead:
		return

	vitality += 1

	health.increase_max_health(
		health_per_vitality,
		true
	)

	print(
		"[Xizane] Vitality: %d, Max HP: %d"
		% [vitality, health.max_health]
	)

func set_resting(value: bool) -> void:
	if health != null and health.is_dead:
		return

	_is_resting = value
	velocity = Vector2.ZERO

	if combat != null and combat.has_method("cancel_attack"):
		combat.cancel_attack()


func is_resting() -> bool:
	return _is_resting



func _animate_character(delta: float) -> void:
	var grounded: bool = is_on_floor()
	var dashing: bool = movement.is_dashing()
	var attacking: bool = combat.is_attacking()

	var speed_ratio: float = clampf(
		absf(velocity.x) / movement.run_speed,
		0.0,
		1.0
	)

	var smoothing: float = clampf(
		animation_smoothing * delta,
		0.0,
		1.0
	)

	_idle_time += delta

	if not _is_resting:
		visual_root.scale.x = movement.facing_direction

	if grounded and speed_ratio > 0.08 and not dashing and not attacking:
		_stride_phase += absf(velocity.x) * run_stride_speed * delta

	var stride: float = sin(_stride_phase)

	var target_front_leg: float = 0.0
	var target_back_leg: float = 0.0
	var target_front_arm: float = 0.0
	var target_back_arm: float = 0.0
	var target_torso: float = 0.0
	var target_sword: float = -0.12

	if _is_resting:
		target_torso = 0.08
		target_front_leg = 1.18
		target_back_leg = 1.05
		target_front_arm = 0.35
		target_back_arm = -0.25
		target_sword = -0.35

	elif attacking:
		var progress: float = combat.attack_progress()
		var swing: float = smoothstep(
			0.06,
			0.82,
			progress
		)

		target_front_leg = -0.08
		target_back_leg = 0.10
		target_back_arm = 0.18

		match combat.attack_direction():
			"up":
				target_torso = -0.10
				target_front_arm = lerpf(
					-0.55,
					-2.65,
					swing
				)
				target_sword = -0.35

			"down":
				target_torso = 0.18
				target_front_leg = -0.25
				target_back_leg = 0.30
				target_front_arm = lerpf(
					0.30,
					-0.45,
					swing
				)
				target_sword = lerpf(
					0.0,
					-0.90,
					swing
				)

			_:
				target_torso = lerpf(
					-0.08,
					0.16,
					swing
				)
				target_front_arm = lerpf(
					-2.10,
					1.25,
					swing
				)
				target_sword = lerpf(
					-0.55,
					0.45,
					swing
				)

	elif dashing:
		target_torso = 0.26
		target_front_leg = -0.52
		target_back_leg = 0.42
		target_front_arm = -0.55
		target_back_arm = 0.38
		target_sword = -0.70

	elif not grounded:
		if velocity.y < 0.0:
			target_torso = -0.06
			target_front_leg = -0.22
			target_back_leg = 0.28
			target_front_arm = -0.30
			target_back_arm = 0.20
		else:
			target_torso = 0.06
			target_front_leg = 0.22
			target_back_leg = -0.18
			target_front_arm = 0.15
			target_back_arm = -0.20

	elif speed_ratio > 0.08:
		target_front_leg = stride * leg_swing_angle
		target_back_leg = -stride * leg_swing_angle
		target_front_arm = -stride * 0.18
		target_back_arm = stride * 0.30
		target_torso = 0.10 * speed_ratio

	if _is_resting:
		target_torso = 0.08

		# Legs bend forward/down into a seated pose.
		target_front_leg = 1.18
		target_back_leg = 1.05

		# Arms rest naturally.
		target_front_arm = 0.35
		target_back_arm = -0.25

		target_sword = -0.35

	if attacking:
		var progress: float = combat.attack_progress()
		# V4 wider sword swing
		var swing: float = smoothstep(0.06, 0.82, progress)

		target_front_leg = -0.08
		target_back_leg = 0.10
		target_back_arm = 0.18

		match combat.attack_direction():
			"up":
				target_torso = -0.10
				target_front_arm = lerpf(-0.55, -2.65, swing)
				target_sword = -0.35

			"down":
				target_torso = 0.18
				target_front_leg = -0.25
				target_back_leg = 0.30
				target_front_arm = lerpf(0.30, -0.45, swing)
				target_sword = lerpf(0.0, -0.90, swing)

			_:
				target_torso = lerpf(-0.08, 0.16, swing)
				target_front_arm = lerpf(-2.10, 1.25, swing)
				target_sword = lerpf(-0.55, 0.45, swing)


	elif dashing:
		target_torso = 0.26
		target_front_leg = -0.52
		target_back_leg = 0.42
		target_front_arm = -0.55
		target_back_arm = 0.38
		target_sword = -0.70

	elif not grounded:
		if velocity.y < 0.0:
			target_torso = -0.06
			target_front_leg = -0.22
			target_back_leg = 0.28
			target_front_arm = -0.30
			target_back_arm = 0.20
		else:
			target_torso = 0.06
			target_front_leg = 0.22
			target_back_leg = -0.18
			target_front_arm = 0.15
			target_back_arm = -0.20

	elif speed_ratio > 0.08:
		target_front_leg = stride * leg_swing_angle
		target_back_leg = -stride * leg_swing_angle
		target_front_arm = -stride * 0.18
		target_back_arm = stride * 0.30
		target_torso = 0.10 * speed_ratio

	if grounded and not _was_grounded:
		_landing_timer = 0.12

	_was_grounded = grounded
	_landing_timer = maxf(_landing_timer - delta, 0.0)

	var landing_amount: float = _landing_timer / 0.12
	if not grounded:
		landing_amount = 0.0

	front_leg.rotation = lerp_angle(front_leg.rotation, target_front_leg, smoothing)
	back_leg.rotation = lerp_angle(back_leg.rotation, target_back_leg, smoothing)
	front_arm.rotation = lerp_angle(front_arm.rotation, target_front_arm, smoothing)
	back_arm.rotation = lerp_angle(back_arm.rotation, target_back_arm, smoothing)
	torso.rotation = lerp_angle(torso.rotation, target_torso, smoothing)
	sword.rotation = lerp_angle(sword.rotation, target_sword, smoothing)

	var idle_bob: float = sin(_idle_time * 2.5) * 0.7
	var run_bob: float = absf(stride) * 2.0 * speed_ratio
	var bob: float = idle_bob

	if _is_resting:
		bob = 19.0

	elif grounded and speed_ratio > 0.08 and not attacking:
		bob = -run_bob

	if dashing:
		bob = -1.5

	if _is_resting:
		target_torso = 0.08

		# Legs bend forward/down into a seated pose.
		target_front_leg = 1.18
		target_back_leg = 1.05

		# Arms rest naturally.
		target_front_arm = 0.35
		target_back_arm = -0.25

		target_sword = -0.35

	elif attacking:
		bob = -0.6

	torso.position.y = lerpf(
		torso.position.y,
		-7.0 + bob + landing_amount * 3.0,
		smoothing
	)

	head.rotation = lerp_angle(
		head.rotation,
		-target_torso * 0.30,
		smoothing
	)

	hat.position.y = lerpf(
		hat.position.y,
		-12.0 + absf(stride) * speed_ratio * 1.2,
		smoothing * 0.65
	)

	var target_color: Color = Color.WHITE
	if dashing:
		target_color = Color(1.18, 1.12, 1.02)
	elif attacking:
		target_color = Color(1.10, 1.06, 1.00)

	visual_root.modulate = visual_root.modulate.lerp(target_color, smoothing)



func is_staggered() -> bool:
	return _stagger_timer > 0.0

func receive_enemy_hit(
	amount: int,
	attacker_position: Vector2,
	poise_damage: float = 28.0
) -> void:
	if not health.take_damage(amount):
		return

	print(
		"[Xizane] HP: %d/%d"
		% [health.current_health, health.max_health]
	)

	poise = maxf(0.0, poise - poise_damage)
	_poise_delay = poise_recovery_delay
	if poise <= 0.0:
		poise = max_poise
		_stagger_timer = stagger_duration
		if combat.has_method("cancel_attack"):
			combat.cancel_attack()
	var push_direction: float = (
		1.0 if global_position.x >= attacker_position.x
		else -1.0
	)

	velocity.x = push_direction * 300.0
	velocity.y = -210.0

	_flash_damage()



func _flash_damage() -> void:
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	var visual := get_node_or_null("VisualRoot") as CanvasItem

	if visual == null:
		return

	visual.modulate = Color(1.0, 0.35, 0.35)

	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(
		visual,
		"modulate",
		Color.WHITE,
		0.25
	)

func _on_died() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	print("[Xizane] Defeated")
