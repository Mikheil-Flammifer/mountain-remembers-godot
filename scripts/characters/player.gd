class_name XizanePlayer
extends CharacterBody2D

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
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

var _stride_phase: float = 0.0
var _idle_time: float = 0.0
var _was_grounded: bool = false
var _landing_timer: float = 0.0
var _attack_was_pressed: bool = false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 6.0

	if health != null:
		health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	_handle_attack_input()

	if movement != null:
		movement.physics_tick(self, delta)

	if combat != null:
		combat.physics_tick(self, movement.facing_direction, delta)

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

	combat.try_start_attack()


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

	if attacking:
		var progress: float = combat.attack_progress()

		var swing: float = smoothstep(
			0.10,
			0.85,
			progress
		)

		target_torso = lerpf(-0.08, 0.16, swing)
		target_front_leg = -0.08
		target_back_leg = 0.10

		# Swing the arm from an overhead position forward.
		target_front_arm = lerpf(-1.35, 0.90, swing)
		target_back_arm = 0.18
		target_sword = lerpf(-0.20, 0.35, swing)

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

	if grounded and speed_ratio > 0.08 and not attacking:
		bob = -run_bob

	if dashing:
		bob = -1.5

	if attacking:
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

func _on_died() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)