extends CharacterBody2D
## Reusable Jvari combatant. The blade can strike this CharacterBody2D directly.
## Threats have visible windups, recovery, and per-attack hit deduplication.

@export_enum("sentry", "raider", "wraith", "warden") var archetype: String = "sentry"
@export_range(0, 4, 1) var difficulty: int = 0

var max_health: int = 35
var health: int = 35
var damage: int = 9
var speed: float = 90.0
var facing: float = -1.0
var _home: Vector2
var _player: CharacterBody2D
var _clock: float = 0.0
var _phase: String = "patrol"
var _timer: float = 0.0
var _cooldown: float = 0.0
var _swing_hit: bool = false
var _dead: bool = false
var _hurt: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0 if archetype == "wraith" else 1
	_home = global_position
	match archetype:
		"raider":
			max_health = 48 + difficulty * 9
			damage = 12 + difficulty * 2
			speed = 145 + difficulty * 9
		"wraith":
			max_health = 25 + difficulty * 5
			damage = 10 + difficulty * 2
			speed = 110 + difficulty * 8
		"warden":
			max_health = 120 + difficulty * 20
			damage = 18 + difficulty * 2
			speed = 60
		_:
			max_health = 38 + difficulty * 8
			damage = 10 + difficulty * 2
			speed = 84 + difficulty * 8
	health = max_health
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 18 if archetype != "warden" else 26
	shape.height = 58 if archetype != "warden" else 88
	collision.shape = shape
	add_child(collision)
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_clock += delta
	_timer = maxf(0.0, _timer - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_hurt = maxf(0.0, _hurt - delta)
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	var offset := Vector2(9999.0, 9999.0)
	if is_instance_valid(_player):
		offset = _player.global_position - global_position
	if absf(offset.x) < 450.0:
		facing = 1.0 if offset.x > 0 else -1.0
	if _phase == "warning":
		velocity.x = move_toward(velocity.x, 0.0, 1700.0 * delta)
		if _timer <= 0.0:
			_phase = "strike"
			_timer = 0.18
			_swing_hit = false
	elif _phase == "strike":
		velocity.x = 0.0
		_try_strike(offset)
		if _timer <= 0.0:
			_phase = "recover"
			_timer = 0.45 if archetype != "warden" else 0.85
			_cooldown = 0.85
	elif _phase == "recover" or _hurt > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
		if _timer <= 0.0:
			_phase = "patrol"
	else:
		var distance: float = 76.0 if archetype != "warden" else 108.0
		if absf(offset.x) < distance and absf(offset.y) < 95.0 and _cooldown <= 0.0:
			_phase = "warning"
			_timer = 0.48 if archetype != "raider" else 0.31
		elif archetype == "wraith":
			velocity.x = facing * speed * 0.75 if absf(offset.x) < 300.0 else sin(_clock * 0.8) * speed
		else:
			var in_pursuit: bool = absf(offset.x) < 350.0 and absf(offset.y) < 140.0
			var target: float = facing * speed if in_pursuit else sin(_clock * 0.85) * speed * 0.60
			velocity.x = move_toward(velocity.x, target, 520.0 * delta)
	if archetype == "wraith":
		velocity.y = cos(_clock * 2.3) * 64.0
		move_and_slide()
	else:
		velocity.y = minf(950.0, velocity.y + 1500.0 * delta)
		move_and_slide()
		if global_position.distance_to(_home) > 520.0 and absf(offset.x) > 450.0:
			facing = -1.0 if global_position.x > _home.x else 1.0
		if not is_on_floor() and global_position.y > 930.0:
			queue_free()
	queue_redraw()

func _try_strike(offset: Vector2) -> void:
	if _swing_hit or not is_instance_valid(_player) or not _player.has_method("receive_enemy_hit"):
		return
	if offset.x * facing < -18.0 or offset.x * facing > (117.0 if archetype == "warden" else 85.0):
		return
	if absf(offset.y) > (105.0 if archetype == "wraith" else 70.0):
		return
	_swing_hit = true
	_player.call("receive_enemy_hit", damage, global_position, 35.0 if archetype == "warden" else 24.0)

func take_hit(amount: int, knockback: Vector2, poise_damage: float = 20.0) -> void:
	if _dead or amount <= 0:
		return
	health -= amount
	if health <= 0:
		_dead = true
		set_physics_process(false)
		collision_layer = 0
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.36)
		tween.tween_callback(queue_free)
	else:
		_hurt = 0.22
		if poise_damage >= (28.0 if archetype == "warden" else 15.0):
			_phase = "recover"
			_timer = 0.3
			velocity = knockback * 0.22
	queue_redraw()

func _draw() -> void:
	var warning: bool = _phase == "warning"
	var color := Color("#424a41")
	if archetype == "raider":
		color = Color("#5a4a3d")
	elif archetype == "wraith":
		color = Color("#72877d", 0.91)
	elif archetype == "warden":
		color = Color("#56564d")
	if _hurt > 0:
		color = Color("#c17d5a")
	# Bodies, faces and weapons are deliberately graphical, not generic capsules.
	if archetype == "wraith":
		draw_colored_polygon(PackedVector2Array([Vector2(-24, -18),Vector2(0,-45),Vector2(24,-18),Vector2(19,20),Vector2(0,7),Vector2(-19,20)]), color)
		draw_circle(Vector2(0, -15), 8, Color("#d4d0ad"))
		draw_circle(Vector2(-3, -15), 2, Color("#333d38"))
	else:
		var scale_factor: float = 1.45 if archetype == "warden" else 1.0
		draw_rect(Rect2(Vector2(-17,-38)*scale_factor, Vector2(34,63)*scale_factor), color)
		draw_circle(Vector2(0,-49)*scale_factor, 13.0*scale_factor, color)
		draw_line(Vector2(10,-24)*scale_factor, Vector2(48*facing, -13)*scale_factor, Color("#b8ae8e"), 5.0)
		if archetype == "warden":
			draw_rect(Rect2(Vector2(-26,-48), Vector2(52,7)), Color("#a19475"))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(-16,-61),Vector2(0,-72),Vector2(17,-61)]), Color("#343c37"))
	if warning:
		draw_arc(Vector2(60.0 * facing, 14.0), 43.0, 0.0, TAU, 24, Color("#edb36b"), 3.0)
	if _phase == "strike":
		draw_line(Vector2(8*facing,-22),Vector2(100*facing,-11),Color("#f0c899"),6.0)
	# Compact in-world health bar only when hurt.
	if health < max_health and not _dead:
		var ratio: float = clampf(float(health) / float(max_health), 0.0, 1.0)
		draw_rect(Rect2(-30,-95,60,5), Color("#292e2a"))
		draw_rect(Rect2(-30,-95,60*ratio,5), Color("#bc7655"))
