class_name AludaVisual
extends ActorVisual
## Polygon rig: replace this scene to change Aluda's appearance.

@onready var body: Node2D = $Body
@onready var front_arm: Node2D = $Body/FrontArm
@onready var shield_arm: Node2D = $Body/ShieldArm
@onready var front_leg: Node2D = $FrontLeg
@onready var back_leg: Node2D = $BackLeg

var _time: float = 0.0


func update_visual(state: ActorVisualState, delta: float) -> void:
	if state == null:
		return
	_time += delta
	set_facing(state.facing_direction)
	var smoothing_ride := clampf(delta * 10.0, 0.0, 1.0)
	if state.is_mounted:
		# Seated: legs astride the horse, a forward lean that deepens at a gallop.
		var lean := 0.06 + 0.16 * clampf(state.get_speed_ratio(), 0.0, 1.0)
		front_leg.rotation = lerp_angle(front_leg.rotation, -0.75, smoothing_ride)
		back_leg.rotation = lerp_angle(back_leg.rotation, -0.6, smoothing_ride)
		body.rotation = lerp_angle(body.rotation, lean, smoothing_ride)
		body.position.y = lerpf(body.position.y, state.ride_bounce, smoothing_ride)
		var reins := -0.9 - state.ride_bounce * 0.03
		front_arm.rotation = lerp_angle(front_arm.rotation, lerpf(-1.8, 1.2, state.attack_progress) if state.is_attacking else reins, smoothing_ride)
		shield_arm.rotation = lerp_angle(shield_arm.rotation, -0.9 if state.is_blocking else -0.7, smoothing_ride)
		play_animation(&"attack" if state.is_attacking else &"ride")
		return
	body.rotation = lerp_angle(body.rotation, 0.0, clampf(delta * 10.0, 0.0, 1.0))
	var walking := state.is_grounded and absf(state.velocity.x) > 10.0
	var stride := sin(_time * 10.0) if walking else 0.0
	var smoothing := clampf(delta * 14.0, 0.0, 1.0)
	var arm_target := -0.3 * stride
	var shield_target := 0.2 * stride
	if state.is_attacking:
		arm_target = lerpf(-1.8, 1.2, smoothstep(0.0, 1.0, state.attack_progress))
	elif state.is_blocking:
		shield_target = -0.9
	elif not state.is_grounded:
		arm_target = -0.35
	front_leg.rotation = lerp_angle(front_leg.rotation, stride * 0.42, smoothing)
	back_leg.rotation = lerp_angle(back_leg.rotation, -stride * 0.42, smoothing)
	front_arm.rotation = lerp_angle(front_arm.rotation, arm_target, smoothing)
	shield_arm.rotation = lerp_angle(shield_arm.rotation, shield_target, smoothing)
	body.position.y = lerpf(body.position.y, -absf(stride) * 1.3 if walking else 0.0, smoothing)
	if state.is_attacking:
		play_animation(&"attack")
	elif state.is_blocking:
		play_animation(&"block")
	elif not state.is_grounded:
		play_animation(&"jump" if state.velocity.y < 0.0 else &"fall")
	else:
		play_animation(&"run" if walking else &"idle")
