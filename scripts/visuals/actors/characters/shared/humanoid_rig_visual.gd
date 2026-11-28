class_name HumanoidRigVisual
extends ActorVisual
## Shared polygon-rig animation for human characters (same motion as AludaVisual).
## A character scene needs: Body, Body/FrontArm, FrontLeg, BackLeg.
## Body/BackArm is optional (shield or empty hand).

@export var stride_speed: float = 10.0
@export var leg_swing: float = 0.42

@onready var body: Node2D = $Body
@onready var front_arm: Node2D = $Body/FrontArm
@onready var back_arm: Node2D = get_node_or_null("Body/BackArm")
@onready var front_leg: Node2D = $FrontLeg
@onready var back_leg: Node2D = $BackLeg

var _time: float = 0.0


func update_visual(state: ActorVisualState, delta: float) -> void:
	if state == null:
		return
	_time += delta
	set_facing(state.facing_direction)
	var walking := state.is_grounded and absf(state.velocity.x) > 10.0
	var stride := sin(_time * stride_speed) if walking else 0.0
	var smoothing := clampf(delta * 14.0, 0.0, 1.0)
	var arm_target := -0.3 * stride
	var back_target := 0.2 * stride
	if state.is_attacking:
		arm_target = lerpf(-1.8, 1.2, smoothstep(0.0, 1.0, state.attack_progress))
	elif state.is_blocking:
		back_target = -0.9
	elif not state.is_grounded:
		arm_target = -0.35
	front_leg.rotation = lerp_angle(front_leg.rotation, stride * leg_swing, smoothing)
	back_leg.rotation = lerp_angle(back_leg.rotation, -stride * leg_swing, smoothing)
	front_arm.rotation = lerp_angle(front_arm.rotation, arm_target, smoothing)
	if back_arm != null:
		back_arm.rotation = lerp_angle(back_arm.rotation, back_target, smoothing)
	body.position.y = lerpf(body.position.y, -absf(stride) * 1.3 if walking else 0.0, smoothing)
	if state.is_attacking:
		play_animation(&"attack")
	elif state.is_blocking:
		play_animation(&"block")
	elif not state.is_grounded:
		play_animation(&"jump" if state.velocity.y < 0.0 else &"fall")
	else:
		play_animation(&"run" if walking else &"idle")
