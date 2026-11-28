
class_name XizanePolygonVisual
extends ActorVisual
## Procedural polygon-based visual implementation for Xizane.
## Responsible only for appearance, animation and visual effects.


# Rig references

@onready var torso: Node2D = $TorsoRig
@onready var head: Node2D = $TorsoRig/HeadRig
@onready var shield_rig: Node2D = $TorsoRig/ShieldRig

@onready var back_leg: Node2D = $BackLeg
@onready var front_leg: Node2D = $FrontLeg

@onready var back_arm: Node2D = $BackArm
@onready var front_arm: Node2D = $FrontArm

@onready var sword: Node2D = $FrontArm/SwordRig


# Animation configuration

@export_group("Animation")

@export var run_stride_speed: float = 0.062
@export var leg_swing_angle: float = 0.50
@export var animation_smoothing: float = 17.0


# Internal animation state

var _stride_phase: float = 0.0
var _idle_time: float = 0.0

var _was_grounded: bool = false
var _landing_timer: float = 0.0

var _stretch_x: float = 1.0
var _stretch_y: float = 1.0

var _effect_tint: Color = Color.WHITE
var _damage_flash_amount: float = 0.0
var _damage_flash_tween: Tween


func _ready() -> void:
	super._ready()
	_improve_equipment_shapes()


# Main visual update

func update_visual(
	state: ActorVisualState,
	delta: float
) -> void:
	if state == null:
		return

	if state.is_climbing:
		_update_climb_pose(state.climb_phase)
		play_animation(&"climb")
		return

	var grounded: bool = state.is_grounded
	var dashing: bool = state.is_dashing
	var attacking: bool = state.is_attacking
	var blocking: bool = state.is_blocking
	var resting: bool = state.is_resting

	var motion: Vector2 = state.velocity
	var speed_ratio: float = state.get_speed_ratio()

	var smoothing: float = clampf(
		animation_smoothing * delta,
		0.0,
		1.0
	)

	_idle_time += delta

	_update_body_scale(state, smoothing)
	_update_animation_name(state)

	if (
		grounded
		and speed_ratio > 0.08
		and not dashing
		and not attacking
		and not blocking
	):
		_stride_phase += (
			absf(motion.x)
			* run_stride_speed
			* delta
		)

	var stride: float = sin(_stride_phase)

	var target_front_leg: float = 0.0
	var target_back_leg: float = 0.0
	var target_front_arm: float = 0.0
	var target_back_arm: float = 0.0
	var target_torso: float = 0.0
	var target_sword: float = -0.12

	var shield_position := Vector2(-14.0, 0.0)
	var shield_rotation: float = -0.22

	# Resting pose

	if resting:
		target_torso = 0.08
		target_front_leg = 1.18
		target_back_leg = 1.05
		target_front_arm = 0.35
		target_back_arm = -0.25
		target_sword = -0.35

	# Shield blocking

	elif blocking:
		target_torso = -0.11
		target_front_leg = -0.12
		target_back_leg = 0.18
		target_front_arm = -0.42
		target_back_arm = -0.92
		target_sword = -0.72

		shield_position = Vector2(25.0, -5.0)
		shield_rotation = 0.06

	# Sword attacks

	elif attacking:
		var pose: Array = _attack_pose_values(
			state.attack_progress,
			state.attack_direction,
			state.combo_step
		)

		target_front_leg = float(pose[0])
		target_back_leg = float(pose[1])
		target_front_arm = float(pose[2])
		target_back_arm = float(pose[3])
		target_torso = float(pose[4])
		target_sword = float(pose[5])

	# Dash

	elif dashing:
		target_torso = 0.27
		target_front_leg = -0.58
		target_back_leg = 0.46
		target_front_arm = -0.65
		target_back_arm = 0.38
		target_sword = -0.82

	# Airborne movement

	elif not grounded:
		if motion.y < 0.0:
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

	# Running

	elif speed_ratio > 0.08:
		target_front_leg = stride * leg_swing_angle
		target_back_leg = -stride * leg_swing_angle
		target_front_arm = -stride * 0.24
		target_back_arm = stride * 0.33
		target_torso = 0.07 * speed_ratio

	# Landing

	if grounded and not _was_grounded:
		_landing_timer = 0.12

	_was_grounded = grounded
	_landing_timer = maxf(_landing_timer - delta, 0.0)

	# Apply rig animation

	front_leg.rotation = lerp_angle(
		front_leg.rotation,
		target_front_leg,
		smoothing
	)

	back_leg.rotation = lerp_angle(
		back_leg.rotation,
		target_back_leg,
		smoothing
	)

	front_arm.rotation = lerp_angle(
		front_arm.rotation,
		target_front_arm,
		smoothing
	)

	back_arm.rotation = lerp_angle(
		back_arm.rotation,
		target_back_arm,
		smoothing
	)

	torso.rotation = lerp_angle(
		torso.rotation,
		target_torso,
		smoothing
	)

	sword.rotation = lerp_angle(
		sword.rotation,
		target_sword,
		smoothing
	)

	shield_rig.position = shield_rig.position.lerp(
		shield_position,
		smoothing
	)

	shield_rig.rotation = lerp_angle(
		shield_rig.rotation,
		shield_rotation,
		smoothing
	)

	shield_rig.z_index = 4 if blocking else -1

	_update_body_bob(
		state,
		stride,
		speed_ratio,
		target_torso,
		smoothing
	)

	_update_visual_effects(state, smoothing)


func _update_climb_pose(phase: float) -> void:
	var swing := sin(phase) * 0.34
	front_leg.rotation = 0.26 + swing
	back_leg.rotation = 0.26 - swing
	front_arm.rotation = -0.70 - swing
	back_arm.rotation = -0.70 + swing
	torso.rotation = 0.0


# Facing and squash/stretch

func _update_body_scale(
	state: ActorVisualState,
	smoothing: float
) -> void:
	if not is_zero_approx(state.facing_direction):
		facing_direction = (
			1.0 if state.facing_direction > 0.0 else -1.0
		)

	var target_x: float = 1.0
	var target_y: float = 1.0

	if state.is_dashing:
		target_x = 1.08
		target_y = 0.94

	elif (
		not state.is_grounded
		and absf(state.velocity.y) < 100.0
	):
		target_x = 0.98
		target_y = 1.025

	elif _landing_timer > 0.0:
		target_x = 1.025
		target_y = 0.97

	_stretch_x = lerpf(
		_stretch_x,
		target_x,
		smoothing
	)

	_stretch_y = lerpf(
		_stretch_y,
		target_y,
		smoothing
	)

	scale = Vector2(
		absf(visual_scale.x) * facing_direction * _stretch_x,
		visual_scale.y * _stretch_y
	)


# Animation state identification

func _update_animation_name(
	state: ActorVisualState
) -> void:
	if state.is_resting:
		play_animation(&"rest")

	elif state.is_blocking:
		play_animation(&"block")

	elif state.is_attacking:
		match state.attack_direction:
			"up":
				play_animation(&"attack_up")
			"down":
				play_animation(&"attack_down")
			_:
				if state.combo_step == 0:
					play_animation(&"attack_1")
				else:
					play_animation(&"attack_2")

	elif state.is_dashing:
		play_animation(&"dash")

	elif not state.is_grounded:
		if state.velocity.y < 0.0:
			play_animation(&"jump")
		else:
			play_animation(&"fall")

	elif state.get_speed_ratio() > 0.08:
		play_animation(&"run")

	else:
		play_animation(&"idle")


# Idle breathing and body movement

func _update_body_bob(
	state: ActorVisualState,
	stride: float,
	speed_ratio: float,
	target_torso: float,
	smoothing: float
) -> void:
	var idle_bob: float = sin(_idle_time * 2.5) * 0.55

	var run_bob: float = (
		absf(stride)
		* 2.0
		* minf(speed_ratio, 1.0)
	)

	var bob: float = idle_bob

	if state.is_resting:
		bob = 19.0

	elif (
		state.is_grounded
		and speed_ratio > 0.08
		and not state.is_attacking
		and not state.is_blocking
	):
		bob = -run_bob

	elif state.is_dashing:
		bob = -1.8

	elif state.is_attacking:
		bob = -0.6

	var landing_amount: float = (
		_landing_timer / 0.12
		if state.is_grounded
		else 0.0
	)

	torso.position.y = lerpf(
		torso.position.y,
		-7.0 + bob + landing_amount * 3.0,
		smoothing
	)

	head.rotation = lerp_angle(
		head.rotation,
		-target_torso * 0.25,
		smoothing
	)


# Sword attack poses

func _attack_pose_values(
	progress: float,
	direction: String,
	combo_step: int
) -> Array:
	var front_leg_value: float = -0.08
	var back_leg_value: float = 0.12
	var front_arm_value: float = 0.0
	var back_arm_value: float = 0.15
	var torso_value: float = 0.0
	var sword_value: float = -0.20

	# Upward sword attack

	if direction == "up":
		if progress < 0.20:
			var t: float = _ease_in_out(progress / 0.20)

			front_arm_value = lerpf(-0.25, 0.55, t)
			sword_value = lerpf(-0.20, 0.15, t)
			torso_value = lerpf(0.0, 0.10, t)

		elif progress < 0.68:
			var t: float = _ease_out(
				(progress - 0.20) / 0.48
			)

			front_arm_value = lerpf(0.55, -2.65, t)
			sword_value = lerpf(0.15, -0.48, t)
			torso_value = lerpf(0.10, -0.15, t)

		else:
			var t: float = _ease_in_out(
				(progress - 0.68) / 0.32
			)

			front_arm_value = lerpf(-2.65, -0.18, t)
			sword_value = lerpf(-0.48, -0.16, t)
			torso_value = lerpf(-0.15, 0.0, t)

	# Downward sword attack

	elif direction == "down":
		front_leg_value = -0.24
		back_leg_value = 0.31

		if progress < 0.18:
			var t: float = _ease_in_out(progress / 0.18)

			front_arm_value = lerpf(-0.35, -1.15, t)
			torso_value = lerpf(0.0, -0.08, t)

		elif progress < 0.66:
			var t: float = _ease_out(
				(progress - 0.18) / 0.48
			)

			front_arm_value = lerpf(-1.15, 0.42, t)
			sword_value = lerpf(-0.35, -1.05, t)
			torso_value = lerpf(-0.08, 0.22, t)

		else:
			var t: float = _ease_in_out(
				(progress - 0.66) / 0.34
			)

			front_arm_value = lerpf(0.42, -0.12, t)
			sword_value = lerpf(-1.05, -0.18, t)
			torso_value = lerpf(0.22, 0.0, t)

	# First horizontal attack

	elif combo_step == 0:
		if progress < 0.18:
			var t: float = _ease_in_out(progress / 0.18)

			front_arm_value = lerpf(-0.20, -1.85, t)
			sword_value = lerpf(-0.15, -0.58, t)
			torso_value = lerpf(0.0, -0.10, t)

		elif progress < 0.67:
			var t: float = _ease_out(
				(progress - 0.18) / 0.49
			)

			front_arm_value = lerpf(-1.85, 0.95, t)
			sword_value = lerpf(-0.58, 0.32, t)
			torso_value = lerpf(-0.10, 0.16, t)

		else:
			var t: float = _ease_in_out(
				(progress - 0.67) / 0.33
			)

			front_arm_value = lerpf(0.95, -0.18, t)
			sword_value = lerpf(0.32, -0.14, t)
			torso_value = lerpf(0.16, 0.0, t)

	# Second horizontal attack

	else:
		if progress < 0.16:
			var t: float = _ease_in_out(progress / 0.16)

			front_arm_value = lerpf(0.70, 1.12, t)
			sword_value = lerpf(0.18, 0.48, t)
			torso_value = lerpf(0.08, 0.14, t)

		elif progress < 0.66:
			var t: float = _ease_out(
				(progress - 0.16) / 0.50
			)

			front_arm_value = lerpf(1.12, -1.38, t)
			sword_value = lerpf(0.48, -0.50, t)
			torso_value = lerpf(0.14, -0.13, t)

		else:
			var t: float = _ease_in_out(
				(progress - 0.66) / 0.34
			)

			front_arm_value = lerpf(-1.38, -0.18, t)
			sword_value = lerpf(-0.50, -0.14, t)
			torso_value = lerpf(-0.13, 0.0, t)

	return [
		front_leg_value,
		back_leg_value,
		front_arm_value,
		back_arm_value,
		torso_value,
		sword_value
	]


# Visual effects

func _update_visual_effects(
	state: ActorVisualState,
	smoothing: float
) -> void:
	var target_color: Color = Color.WHITE

	if state.perfect_guard_flash_timer > 0.0:
		target_color = Color(1.20, 1.16, 0.86)

	elif state.shield_flash_timer > 0.0:
		target_color = Color(1.10, 1.07, 0.90)

	elif state.heal_flash_timer > 0.0:
		target_color = Color(0.82, 1.14, 0.91)

	elif state.is_dashing:
		target_color = Color(1.08, 1.06, 1.02)

	_effect_tint = _effect_tint.lerp(
		target_color,
		smoothing
	)

	_apply_visual_tint()


func _apply_visual_tint() -> void:
	var damage_tint: Color = Color.WHITE.lerp(
		Color(1.0, 0.35, 0.35),
		_damage_flash_amount
	)

	modulate = base_tint * _effect_tint * damage_tint


func flash_damage() -> void:
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	_set_damage_flash_amount(1.0)

	_damage_flash_tween = create_tween()

	_damage_flash_tween.tween_method(
		_set_damage_flash_amount,
		1.0,
		0.0,
		0.23
	)


func _set_damage_flash_amount(value: float) -> void:
	_damage_flash_amount = value
	_apply_visual_tint()


# Equipment geometry

func _improve_equipment_shapes() -> void:
	var blade := get_node_or_null(
		"FrontArm/SwordRig/Blade"
	) as Polygon2D

	var blade_highlight := get_node_or_null(
		"FrontArm/SwordRig/BladeHighlight"
	) as Polygon2D

	var guard := get_node_or_null(
		"FrontArm/SwordRig/Guard"
	) as Polygon2D

	var shield_shape := get_node_or_null(
		"TorsoRig/ShieldRig/Shield"
	) as Polygon2D

	var shield_rim := get_node_or_null(
		"TorsoRig/ShieldRig/ShieldRim"
	) as Polygon2D

	var shield_boss := get_node_or_null(
		"TorsoRig/ShieldRig/ShieldBoss"
	) as Polygon2D

	if blade != null:
		blade.polygon = PackedVector2Array([
			Vector2(-1, -6),
			Vector2(5, -6),
			Vector2(7, -44),
			Vector2(4, -64),
			Vector2(2, -70),
			Vector2(0, -64),
			Vector2(-2, -44)
		])

		blade.color = Color("#b9bec1")

	if blade_highlight != null:
		blade_highlight.polygon = PackedVector2Array([
			Vector2(1, -8),
			Vector2(2, -61),
			Vector2(4, -48),
			Vector2(4, -8)
		])

		blade_highlight.color = Color("#e8dfc5")

	if guard != null:
		guard.polygon = PackedVector2Array([
			Vector2(-10, -8),
			Vector2(13, -8),
			Vector2(11, -3),
			Vector2(-8, -3)
		])

	if shield_shape != null:
		shield_shape.polygon = PackedVector2Array([
			Vector2(0, -20),
			Vector2(13, -15),
			Vector2(18, -3),
			Vector2(15, 12),
			Vector2(0, 22),
			Vector2(-15, 12),
			Vector2(-18, -3),
			Vector2(-13, -15)
		])

		shield_shape.color = Color("#2e2922")

	if shield_rim != null:
		shield_rim.polygon = PackedVector2Array([
			Vector2(0, -17),
			Vector2(10, -13),
			Vector2(14, -2),
			Vector2(11, 10),
			Vector2(0, 17),
			Vector2(-11, 10),
			Vector2(-14, -2),
			Vector2(-10, -13)
		])

		shield_rim.color = Color("#6e5938")

	if shield_boss != null:
		shield_boss.polygon = PackedVector2Array([
			Vector2(0, -6),
			Vector2(6, 0),
			Vector2(0, 6),
			Vector2(-6, 0)
		])

		shield_boss.color = Color("#a28b5c")

	shield_rig.scale = Vector2(1.18, 1.18)
	sword.scale = Vector2(1.04, 1.08)


# Animation interpolation utilities

func _ease_out(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func _ease_in_out(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
