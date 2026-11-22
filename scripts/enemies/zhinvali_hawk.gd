extends CharacterBody2D

## Zhinvali cliff hawk. No warning circle: attack timing is telegraphed by the
## hawk climbing above Xizane, folding its wings and flashing its warm chest.
## It follows the player through the encounter, then commits to a locked dive.

@export_group("Combat")
@export var score_reward: int = 4
@export var max_health: int = 26
@export var damage: int = 9
@export var detection_radius: float = 560.0
@export var lose_radius: float = 820.0
@export var telegraph_duration: float = 0.58
@export var dive_speed: float = 520.0
@export var attack_cooldown: float = 1.9

@export_group("Movement")
@export var patrol_speed: float = 138.0
@export var pursue_speed: float = 205.0
@export var pursue_height: float = 165.0

var health: int = 26
var _player: CharacterBody2D
var _home: Vector2
var _clock: float = 0.0
var _state: String = "patrol"
var _timer: float = 0.0
var _cooldown: float = 0.0
var _hit_this_dive: bool = false
var _dead: bool = false
var _hurt_timer: float = 0.0
var _dive_target: Vector2
var _facing: float = -1.0


func _ready() -> void:
	health = max_health
	_home = global_position
	_dive_target = _home
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 0
	add_to_group("zhinvali_enemy")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	add_child(shape)

	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_clock += delta
	_timer = maxf(0.0, _timer - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	var has_player: bool = is_instance_valid(_player)
	var player_distance: float = 99999.0
	if has_player:
		player_distance = global_position.distance_to(_player.global_position)
		if absf(_player.global_position.x - global_position.x) > 8.0:
			_facing = 1.0 if _player.global_position.x > global_position.x else -1.0

	match _state:
		"patrol":
			_update_patrol(has_player, player_distance, delta)
		"pursue":
			_update_pursuit(has_player, player_distance, delta)
		"telegraph":
			_update_telegraph(has_player, delta)
		"dive":
			_update_dive(has_player, delta)
		"recover":
			_update_recover(has_player, player_distance, delta)
		"hurt":
			velocity = velocity.move_toward(Vector2.ZERO, 720.0 * delta)
			if _timer <= 0.0:
				_state = "pursue" if has_player and player_distance <= lose_radius else "patrol"

	move_and_slide()
	queue_redraw()


func _update_patrol(has_player: bool, player_distance: float, delta: float) -> void:
	if has_player and player_distance <= detection_radius:
		_state = "pursue"
		return

	var target := _home + Vector2(
		sin(_clock * 0.82) * 145.0,
		cos(_clock * 0.60) * 48.0
	)
	_move_toward_point(target, patrol_speed, 680.0, delta)


func _update_pursuit(has_player: bool, player_distance: float, delta: float) -> void:
	if not has_player or player_distance > lose_radius:
		_state = "patrol"
		return

	var side: float = -95.0 if _facing > 0.0 else 95.0
	var target: Vector2 = _player.global_position + Vector2(side, -pursue_height)
	_move_toward_point(target, pursue_speed, 980.0, delta)

	var horizontal_ready: bool = absf(global_position.x - _player.global_position.x) < 190.0
	var vertical_ready: bool = global_position.y < _player.global_position.y - 95.0
	if _cooldown <= 0.0 and horizontal_ready and vertical_ready:
		_state = "telegraph"
		_timer = telegraph_duration
		velocity *= 0.35


func _update_telegraph(has_player: bool, delta: float) -> void:
	# Hold above the target and visibly tuck wings. No artificial circle marker.
	velocity = velocity.move_toward(Vector2.ZERO, 920.0 * delta)
	if has_player and absf(_player.global_position.x - global_position.x) > 6.0:
		_facing = 1.0 if _player.global_position.x > global_position.x else -1.0

	if _timer <= 0.0:
		_state = "dive"
		_timer = 1.0
		_hit_this_dive = false
		if has_player:
			_dive_target = _player.global_position + Vector2(_player.velocity.x * 0.10, -12.0)
		else:
			_dive_target = global_position + Vector2(_facing * 180.0, 220.0)


func _update_dive(has_player: bool, _delta: float) -> void:
	var offset: Vector2 = _dive_target - global_position
	if offset.length() > 3.0:
		velocity = offset.normalized() * dive_speed

	if (
		has_player
		and not _hit_this_dive
		and global_position.distance_to(_player.global_position) < 58.0
	):
		if _player.has_method("receive_enemy_hit"):
			_player.call("receive_enemy_hit", damage, global_position, 19.0)
		_hit_this_dive = true

	if offset.length() < 24.0 or _timer <= 0.0 or _hit_this_dive:
		_state = "recover"
		_timer = 0.78
		_cooldown = attack_cooldown
		velocity.y = -pursue_speed


func _update_recover(has_player: bool, player_distance: float, delta: float) -> void:
	var target: Vector2 = _home + Vector2(0.0, -40.0)
	if has_player and player_distance <= lose_radius:
		target = _player.global_position + Vector2(-_facing * 120.0, -pursue_height - 45.0)
	_move_toward_point(target, pursue_speed * 1.08, 900.0, delta)

	if _timer <= 0.0:
		_state = "pursue" if has_player and player_distance <= lose_radius else "patrol"


func _move_toward_point(target: Vector2, speed: float, acceleration: float, delta: float) -> void:
	var offset: Vector2 = target - global_position
	var desired := Vector2.ZERO
	if offset.length() > 4.0:
		desired = offset.normalized() * speed
	velocity = velocity.move_toward(desired, acceleration * delta)


func take_hit(amount: int, knockback: Vector2, _poise_damage: float = 0.0) -> void:
	if _dead or amount <= 0:
		return

	health -= amount
	_hurt_timer = 0.18

	if health <= 0:
		_award_score()
		_dead = true
		set_physics_process(false)
		collision_layer = 0
		var tween := create_tween()
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.28)
		tween.parallel().tween_property(self, "position:y", position.y + 72.0, 0.28)
		tween.tween_callback(queue_free)
		return

	_state = "hurt"
	_timer = 0.32
	_cooldown = maxf(_cooldown, 0.9)
	velocity = knockback * 0.58
	queue_redraw()


func _award_score() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("add_score"):
		player.call("add_score", score_reward)


func _draw() -> void:
	var body_color: Color = Color("#303a38")
	var chest_color: Color = Color("#59625c")
	if _hurt_timer > 0.0:
		body_color = Color("#a56a58")
		chest_color = Color("#c18a6a")
	elif _state == "telegraph":
		chest_color = Color("#b8794e")

	var flap: float = sin(_clock * (13.0 if _state != "telegraph" else 7.0))
	var wing_drop: float = 10.0 * flap
	if _state == "telegraph":
		wing_drop = lerpf(3.0, 19.0, 1.0 - _timer / maxf(telegraph_duration, 0.001))

	# Layered wings give the bird a readable silhouette without a warning ring.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8,-5), Vector2(-70,-34-wing_drop), Vector2(-48,-2),
		Vector2(-32,15), Vector2(-7,10)
	]), body_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8,-5), Vector2(70,-34-wing_drop), Vector2(48,-2),
		Vector2(32,15), Vector2(7,10)
	]), body_color)

	for i in range(4):
		var feather_x: float = 28.0 + float(i) * 9.0
		draw_line(Vector2(feather_x, -9.0), Vector2(feather_x + 18.0, -22.0 - wing_drop * 0.35), Color("#202927"), 3.0)
		draw_line(Vector2(-feather_x, -9.0), Vector2(-feather_x - 18.0, -22.0 - wing_drop * 0.35), Color("#202927"), 3.0)

	draw_circle(Vector2(0,-1), 15.0, chest_color)
	draw_circle(Vector2(9.0 * _facing,-8), 8.5, Color("#424b47"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(14.0 * _facing,-7), Vector2(31.0 * _facing,-3), Vector2(15.0 * _facing,1)
	]), Color("#b69b68"))
	draw_circle(Vector2(11.0 * _facing,-10), 2.2, Color("#dfc277"))

	# Tail and talons become prominent during the attack tell.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8,9), Vector2(-3,27), Vector2(0,13), Vector2(4,28), Vector2(9,8)
	]), Color("#252e2c"))
	if _state in ["telegraph", "dive"]:
		draw_line(Vector2(-5,12), Vector2(-9,24), Color("#a88a5e"), 2.0)
		draw_line(Vector2(5,12), Vector2(9,24), Color("#a88a5e"), 2.0)

	if health < max_health and not _dead:
		draw_rect(Rect2(-29,-58,58,5), Color("#242a28"))
		draw_rect(Rect2(-29,-58,58.0 * float(health) / float(max_health),5), Color("#b7775e"))
