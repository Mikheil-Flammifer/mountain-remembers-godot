extends CharacterBody2D

## Zhinvali road archer. Pursues to bow range, retreats when pressured, tracks
## Xizane during a readable bow-draw telegraph, and has a short close-range bash.
## No warning circles are used; posture, bowstring and arrowhead communicate timing.

const ArrowScene: PackedScene = preload("res://scenes/enemies/zhinvali_arrow.tscn")

@export_group("Combat")
@export var score_reward: int = 7
@export var max_health: int = 52
@export var arrow_damage: int = 11
@export var detection_distance: float = 850.0
@export var lose_distance: float = 1080.0
@export var preferred_distance: float = 390.0
@export var too_close_distance: float = 185.0
@export var fire_cooldown: float = 1.45
@export var aim_duration: float = 0.68
@export var bash_damage: int = 6
@export var bash_range: float = 82.0

@export_group("Movement")
@export var patrol_speed: float = 52.0
@export var pursue_speed: float = 145.0
@export var retreat_speed: float = 175.0
@export var acceleration: float = 900.0

var health: int = 52
var _player: CharacterBody2D
var _home_x: float
var _facing: float = -1.0
var _state: String = "patrol"
var _timer: float = 0.0
var _cooldown: float = 0.45
var _clock: float = 0.0
var _hurt_timer: float = 0.0
var _dead: bool = false
var _probe: RayCast2D
var _aim_direction: Vector2 = Vector2.LEFT
var _bash_hit: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 8.0
	health = max_health
	_home_x = global_position.x
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	add_to_group("zhinvali_enemy")

	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.height = 84.0
	capsule.radius = 18.0
	shape.position = Vector2(0.0, -33.0)
	shape.shape = capsule
	add_child(shape)

	_probe = RayCast2D.new()
	_probe.enabled = true
	_probe.collision_mask = 1
	_probe.exclude_parent = true
	add_child(_probe)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_clock += delta
	_timer = maxf(0.0, _timer - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	var difference := Vector2(99999.0, 99999.0)
	if is_instance_valid(_player):
		difference = _player.global_position - global_position

	match _state:
		"hurt":
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
			if _timer <= 0.0:
				_state = "engage"
		"aim":
			_update_aim(delta)
		"shot_recover":
			velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
			if _timer <= 0.0:
				_state = "engage"
		"bash_windup":
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			if _timer <= 0.0:
				_state = "bash"
				_timer = 0.18
				_bash_hit = false
		"bash":
			_update_bash(delta)
		"bash_recover":
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			if _timer <= 0.0:
				_state = "engage"
		_:
			_update_engagement(difference, delta)

	velocity.y = minf(980.0, velocity.y + 1600.0 * delta)
	move_and_slide()
	queue_redraw()


func _update_engagement(difference: Vector2, delta: float) -> void:
	var has_player: bool = is_instance_valid(_player)
	if not has_player:
		_patrol(delta)
		return

	var distance_x: float = absf(difference.x)
	var visible: bool = distance_x <= detection_distance and absf(difference.y) <= 250.0
	var still_engaged: bool = distance_x <= lose_distance and absf(difference.y) <= 340.0

	if _state == "patrol" and not visible:
		_patrol(delta)
		return
	if not still_engaged:
		_state = "patrol"
		_patrol(delta)
		return

	_state = "engage"
	if absf(difference.x) > 8.0:
		_facing = 1.0 if difference.x > 0.0 else -1.0

	if distance_x <= bash_range and absf(difference.y) < 90.0 and _cooldown <= 0.0:
		_state = "bash_windup"
		_timer = 0.22
		velocity.x = 0.0
		return

	if distance_x < too_close_distance:
		var retreat_direction: float = -_facing
		if _can_step(retreat_direction):
			velocity.x = move_toward(velocity.x, retreat_direction * retreat_speed, acceleration * 1.15 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1300.0 * delta)
		return

	if distance_x > preferred_distance + 95.0:
		if _can_step(_facing):
			velocity.x = move_toward(velocity.x, _facing * pursue_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		return

	velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
	if _cooldown <= 0.0 and distance_x >= too_close_distance * 0.82:
		_state = "aim"
		_timer = aim_duration


func _patrol(delta: float) -> void:
	if global_position.x < _home_x - 180.0:
		_facing = 1.0
	elif global_position.x > _home_x + 180.0:
		_facing = -1.0

	if _can_step(_facing):
		velocity.x = move_toward(velocity.x, _facing * patrol_speed, 520.0 * delta)
	else:
		_facing *= -1.0
		velocity.x = 0.0


func _update_aim(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1450.0 * delta)
	if is_instance_valid(_player):
		var predicted: Vector2 = _player.global_position + _player.velocity * 0.14
		_aim_direction = (predicted - _bow_origin()).normalized()
		if absf(_aim_direction.x) > 0.08:
			_facing = 1.0 if _aim_direction.x > 0.0 else -1.0

	if _timer <= 0.0:
		_fire_arrow()
		_state = "shot_recover"
		_timer = 0.46
		_cooldown = fire_cooldown


func _update_bash(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _facing * 185.0, 1900.0 * delta)
	if not _bash_hit and is_instance_valid(_player):
		var offset: Vector2 = _player.global_position - global_position
		if offset.x * _facing >= -10.0 and offset.x * _facing <= 92.0 and absf(offset.y) < 85.0:
			if _player.has_method("receive_enemy_hit"):
				_player.call("receive_enemy_hit", bash_damage, global_position, 14.0)
			_bash_hit = true

	if _timer <= 0.0:
		_state = "bash_recover"
		_timer = 0.42
		_cooldown = maxf(_cooldown, 0.85)


func _bow_origin() -> Vector2:
	return global_position + Vector2(33.0 * _facing, -65.0)


func _fire_arrow() -> void:
	if not is_instance_valid(_player):
		return

	var arrow := ArrowScene.instantiate() as Area2D
	if arrow == null:
		return

	get_tree().current_scene.add_child(arrow)
	arrow.global_position = _bow_origin() + _aim_direction * 28.0
	arrow.call("setup", _aim_direction, self, arrow_damage)


func _can_step(direction: float) -> bool:
	_probe.position = Vector2(direction * 36.0, -10.0)
	_probe.target_position = Vector2(0.0, 116.0)
	_probe.force_raycast_update()
	return not is_on_floor() or _probe.is_colliding()


func take_hit(amount: int, knockback: Vector2, _poise_damage: float = 15.0) -> void:
	if _dead or amount <= 0:
		return

	health -= amount
	if health <= 0:
		_award_score()
		_dead = true
		set_physics_process(false)
		collision_layer = 0
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.30)
		tween.tween_callback(queue_free)
		return

	_hurt_timer = 0.24
	_state = "hurt"
	_timer = 0.38
	_cooldown = maxf(_cooldown, 0.72)
	velocity.x = knockback.x * 0.25
	queue_redraw()


func _award_score() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("add_score"):
		player.call("add_score", score_reward)


func _draw() -> void:
	var cloak_color := Color("#42443e")
	var leather_color := Color("#574437")
	if _hurt_timer > 0.0:
		cloak_color = Color("#9e6855")

	var movement_amount: float = clampf(absf(velocity.x) / maxf(retreat_speed, 1.0), 0.0, 1.0)
	var gait: float = sin(_clock * 10.5) * movement_amount

	# Legs and boots.
	draw_line(Vector2(-10,-25), Vector2(-11 + gait * 6.0, 4), Color("#292f2e"), 9.0)
	draw_line(Vector2(10,-25), Vector2(11 - gait * 6.0, 4), Color("#343a38"), 9.0)
	draw_line(Vector2(-14 + gait * 6.0,4), Vector2(-4 + gait * 6.0,4), Color("#1d2221"), 5.0)
	draw_line(Vector2(6 - gait * 6.0,4), Vector2(16 - gait * 6.0,4), Color("#1d2221"), 5.0)

	# Cloak and leather chest layers.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26,-76), Vector2(-17,-101), Vector2(18,-99),
		Vector2(29,-69), Vector2(23,-18), Vector2(-23,-18)
	]), cloak_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14,-88), Vector2(15,-88), Vector2(18,-54),
		Vector2(9,-34), Vector2(-10,-34), Vector2(-18,-55)
	]), leather_color)
	draw_line(Vector2(-14,-72), Vector2(14,-72), Color("#897357"), 3.0)

	# Head and wrapped mountain hood.
	draw_circle(Vector2(0,-103), 16.0, Color("#ad9070"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-21,-104), Vector2(-12,-124), Vector2(12,-122),
		Vector2(22,-102), Vector2(9,-111), Vector2(-7,-110)
	]), Color("#303532"))
	draw_line(Vector2(-8,-100), Vector2(9,-100), Color("#332a23"), 2.0)

	# Quiver on the back; arrows remain visible while aiming.
	draw_line(Vector2(-19.0 * _facing,-78), Vector2(-30.0 * _facing,-119), Color("#654a35"), 7.0)
	for i in range(3):
		var qx: float = -28.0 * _facing + float(i) * 4.0 * _facing
		draw_line(Vector2(qx,-112), Vector2(qx - 3.0 * _facing,-133), Color("#c6b28d"), 2.0)

	var hand := Vector2(18.0 * _facing, -63.0)
	var bow_x: float = 49.0 * _facing
	var bow_color := Color("#8d6844")
	var draw_progress: float = 0.0
	if _state == "aim":
		draw_progress = 1.0 - (_timer / maxf(aim_duration, 0.001))

	# Bow bends visually as the archer draws it.
	var bend: float = lerpf(0.0, 8.0, draw_progress)
	draw_line(hand, Vector2(bow_x - bend * _facing, -88), bow_color, 4.0)
	draw_line(Vector2(bow_x - bend * _facing, -88), Vector2(59.0 * _facing, -63), bow_color, 4.0)
	draw_line(Vector2(59.0 * _facing, -63), Vector2(bow_x - bend * _facing, -37), bow_color, 4.0)
	draw_line(Vector2(bow_x - bend * _facing, -37), hand, bow_color, 4.0)

	if _state == "aim":
		var nock := hand - Vector2(_facing * lerpf(2.0, 20.0, draw_progress), 0.0)
		draw_line(Vector2(bow_x - bend * _facing,-88), nock, Color("#d5c4a2"), 1.4)
		draw_line(nock, Vector2(bow_x - bend * _facing,-37), Color("#d5c4a2"), 1.4)
		draw_line(nock, nock + _aim_direction * 48.0, Color("#d9c7a4"), 2.2)
		# The arrowhead warms near release: a natural telegraph, not a UI circle.
		var tip: Vector2 = nock + _aim_direction * 48.0
		var tip_color: Color = Color("#b9aaa0").lerp(Color("#d98a55"), draw_progress)
		draw_circle(tip, 2.5 + draw_progress * 1.5, tip_color)
	elif _state == "bash_windup":
		draw_line(Vector2(13.0 * _facing,-68), Vector2(42.0 * _facing,-47), Color("#d1b679"), 4.0)

	if health < max_health and not _dead:
		draw_rect(Rect2(-30,-145,60,5), Color("#282d2b"))
		draw_rect(Rect2(-30,-145,60.0 * float(health) / float(max_health),5), Color("#b87a60"))
