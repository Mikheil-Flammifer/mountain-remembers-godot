
class_name MountainWolf
extends CharacterBody2D

enum State {
	PATROL,
	CHASE,
	HURT,
	DEAD
}

@export_group("Movement")
@export var patrol_speed: float = 65.0
@export var chase_speed: float = 135.0
@export var acceleration: float = 650.0
@export var gravity: float = 1200.0

@export_group("Detection")
@export var detection_range: float = 270.0
@export var lose_range: float = 390.0
@export var detection_height: float = 95.0
@export var stop_distance: float = 40.0

@export_group("Health")
@export var max_health: int = 3
@export var hurt_duration: float = 0.28

@onready var visual: Polygon2D = $Visual
@onready var floor_ray: RayCast2D = $FloorAhead
@onready var wall_ray: RayCast2D = $WallAhead

var state: State = State.PATROL
var health: int = 3

var facing: int = -1
var player: Node2D
var hurt_timer: float = 0.0
var dead: bool = false

var _home_position: Vector2
var _patrol_distance: float = 160.0


func _ready() -> void:
	health = max_health
	_home_position = global_position
	_update_rays()

	player = get_tree().get_first_node_in_group(
		"player"
	) as Node2D


func _physics_process(delta: float) -> void:
	if dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	match state:
		State.PATROL:
			_patrol(delta)

		State.CHASE:
			_chase(delta)

		State.HURT:
			_process_hurt(delta)

	move_and_slide()

	_update_visual()


func _patrol(delta: float) -> void:
	if _can_detect_player():
		state = State.CHASE
		return

	if _should_turn():
		_turn()

	# Limit wandering from the starting position.
	if absf(global_position.x - _home_position.x) > _patrol_distance:
		if (
			global_position.x > _home_position.x
			and facing > 0
		) or (
			global_position.x < _home_position.x
			and facing < 0
		):
			_turn()

	velocity.x = move_toward(
		velocity.x,
		facing * patrol_speed,
		acceleration * delta
	)


func _chase(delta: float) -> void:
	if not is_instance_valid(player):
		state = State.PATROL
		return

	var distance: float = global_position.distance_to(
		player.global_position
	)

	if distance > lose_range:
		state = State.PATROL
		return

	var difference: float = (
		player.global_position.x - global_position.x
	)

	if absf(difference) > stop_distance:
		var desired_facing: int = (
			1 if difference > 0.0 else -1
		)

		if desired_facing != facing:
			facing = desired_facing
			_update_rays()

		if _should_turn():
			velocity.x = move_toward(
				velocity.x,
				0.0,
				acceleration * delta
			)
			return

		velocity.x = move_toward(
			velocity.x,
			facing * chase_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			acceleration * delta
		)


func _process_hurt(delta: float) -> void:
	hurt_timer -= delta

	velocity.x = move_toward(
		velocity.x,
		0.0,
		350.0 * delta
	)

	if hurt_timer <= 0.0:
		state = State.CHASE if _can_detect_player() else State.PATROL


func _can_detect_player() -> bool:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(
			"player"
		) as Node2D

	if not is_instance_valid(player):
		return false

	var difference := player.global_position - global_position

	return (
		absf(difference.x) <= detection_range
		and absf(difference.y) <= detection_height
	)


func _should_turn() -> bool:
	if not is_on_floor():
		return false

	floor_ray.force_raycast_update()
	wall_ray.force_raycast_update()

	return (
		not floor_ray.is_colliding()
		or wall_ray.is_colliding()
	)


func _turn() -> void:
	facing *= -1
	_update_rays()


func _update_rays() -> void:
	floor_ray.position = Vector2(30.0 * facing, 0.0)
	floor_ray.target_position = Vector2(0.0, 58.0)

	wall_ray.position = Vector2(0.0, -5.0)
	wall_ray.target_position = Vector2(
		32.0 * facing,
		0.0
	)


func _update_visual() -> void:
	visual.scale.x = float(facing)

	match state:
		State.CHASE:
			visual.modulate = Color(0.75, 0.78, 0.82)

		State.HURT:
			visual.modulate = Color(1.0, 0.35, 0.35)

		_:
			visual.modulate = Color.WHITE


func take_hit(
	amount: int,
	knockback: Vector2
) -> void:
	if dead:
		return

	health = maxi(health - amount, 0)

	print(
		"[MountainWolf] HP: %d/%d"
		% [health, max_health]
	)

	if health <= 0:
		_die()
		return

	state = State.HURT
	hurt_timer = hurt_duration
	velocity = knockback


func _die() -> void:
	dead = true
	state = State.DEAD
	velocity = Vector2.ZERO

	set_physics_process(false)

	# Disable physical collision after defeat.
	$CollisionShape2D.set_deferred(
		"disabled",
		true
	)

	var tween := create_tween()
	tween.tween_property(
		visual,
		"modulate:a",
		0.0,
		0.45
	)
	tween.tween_callback(queue_free)
