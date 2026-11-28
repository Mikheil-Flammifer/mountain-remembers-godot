class_name MountainWolfVisual
extends Node2D
## Presents wolf poses, attack telegraphs, and the health bar.

@onready var rig: Node2D = $Rig
@onready var head: Node2D = $Rig/Head
@onready var lower_jaw: Node2D = $Rig/Head/LowerJaw
@onready var front_leg: Node2D = $Rig/FrontLeg
@onready var back_leg: Node2D = $Rig/BackLeg
@onready var tail: Node2D = $Rig/Tail

var _animation_time: float = 0.0
var _pose: StringName
var _facing: int = 0
var _hp_ratio: float = 1.0


func update_pose(
	pose: StringName, facing: int, movement_amount: float, hp_ratio: float, delta: float
) -> void:
	_animation_time += delta
	if facing != _facing:
		_facing = facing
		if _pose == &"windup":
			queue_redraw()
		# Flip the rig directly to avoid negative-scale decomposition.
		rig.transform = Transform2D(Vector2(float(facing), 0), Vector2.DOWN, rig.position)
	if pose != _pose or hp_ratio != _hp_ratio:
		_pose = pose
		_hp_ratio = hp_ratio
		queue_redraw()

	var run_cycle: float = sin(_animation_time * 10.0)

	# Neutral local pose.
	head.position = Vector2(31.0, -31.0)
	head.rotation = 0.0

	lower_jaw.rotation = 0.0
	front_leg.rotation = 0.0
	back_leg.rotation = 0.0
	tail.rotation = -0.10

	match pose:
		&"patrol":
			if movement_amount > 0.08:
				front_leg.rotation = run_cycle * 0.16 * movement_amount
				back_leg.rotation = -run_cycle * 0.16 * movement_amount
				tail.rotation = -0.10 + sin(_animation_time * 2.5) * 0.05 * movement_amount

		&"chase":
			if movement_amount > 0.08:
				front_leg.rotation = run_cycle * 0.38 * movement_amount
				back_leg.rotation = -run_cycle * 0.38 * movement_amount
			head.rotation = -0.05
			tail.rotation = 0.10

		&"windup":
			# Small crouch: no giant swing.
			head.position = Vector2(29.0, -26.0)
			head.rotation = 0.08
			front_leg.rotation = 0.16
			back_leg.rotation = -0.14
			tail.rotation = 0.18

		&"bite":
			# Visible bite comes from head + jaw, not a fake weapon line.
			head.position = Vector2(43.0, -28.0)
			head.rotation = -0.08
			lower_jaw.rotation = 0.36
			front_leg.rotation = -0.22
			back_leg.rotation = 0.20
			tail.rotation = 0.20

		&"recovery":
			head.position = Vector2(35.0, -29.0)
			head.rotation = 0.05

		&"hurt":
			head.position = Vector2(26.0, -33.0)
			head.rotation = -0.12
			tail.rotation = -0.25

		_:
			pass

	match pose:
		&"windup":
			rig.modulate = Color(1.06, 0.97, 0.88)

		&"hurt":
			rig.modulate = Color(1.0, 0.45, 0.42)

		_:
			rig.modulate = Color.WHITE


func _draw() -> void:
	if _pose == &"windup":
		var warning := Color(
			0.96,
			0.56,
			0.29,
			0.72
		)

		# Small ground warning only.
		draw_arc(
			Vector2(
				42.0 * float(_facing),
				18.0
			),
			28.0,
			0.0,
			TAU,
			24,
			warning,
			2.5
		)

	# Same compact in-world health bar style as the other enemies.
	# It appears only after the wolf has taken damage.
	if _hp_ratio > 0.0 and _hp_ratio < 1.0:
		draw_rect(
			Rect2(-30.0, -95.0, 60.0, 5.0),
			Color("#292e2a")
		)

		draw_rect(
			Rect2(-30.0, -95.0, 60.0 * _hp_ratio, 5.0),
			Color("#bc7655")
		)


func fade_out(duration: float) -> void:
	_pose = &"dead"
	_hp_ratio = 0.0
	queue_redraw()
	create_tween().tween_property(rig, "modulate:a", 0.0, duration)
