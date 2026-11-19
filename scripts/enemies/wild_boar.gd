extends CharacterBody2D
## Reusable wild boar: patrol -> warning snort -> committed charge -> recovery.
## Compatible with Xizane's sword take_hit(damage, knockback) contract.

@export var max_health: int = 70
@export var damage: int = 15
@export var patrol_speed: float = 64.0
@export var charge_speed: float = 345.0
@export var patrol_radius: float = 240.0
@export var detection_distance: float = 340.0

var health: int
var facing: float = -1.0
var _home_x: float
var _player: CharacterBody2D
var _phase: String = "patrol"
var _phase_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _contact_cooldown: float = 0.0
var _hurt_timer: float = 0.0
var _clock: float = 0.0
var _dead: bool = false
var _ledge_probe: RayCast2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	health = max_health
	_home_x = global_position.x
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	var collider := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 23.0
	capsule.height = 54.0
	collider.shape = capsule
	add_child(collider)
	_ledge_probe = RayCast2D.new()
	_ledge_probe.enabled = true
	_ledge_probe.collision_mask = 1
	_ledge_probe.exclude_parent = true
	add_child(_ledge_probe)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_clock += delta
	_phase_timer = maxf(_phase_timer - delta, 0.0)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_contact_cooldown = maxf(_contact_cooldown - delta, 0.0)
	_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	var offset: Vector2 = Vector2(99999.0, 99999.0)
	if is_instance_valid(_player):
		offset = _player.global_position - global_position
	var close_enough: bool = absf(offset.x) < detection_distance and absf(offset.y) < 95.0
	if _phase == "warning":
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
		if _phase_timer <= 0.0:
			_phase = "charge"
			_phase_timer = 0.52
	elif _phase == "charge":
		velocity.x = facing * charge_speed
		if _phase_timer <= 0.0:
			_enter_recovery()
	elif _phase == "recover":
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		if _phase_timer <= 0.0:
			_phase = "patrol"
	elif _hurt_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
	else:
		if close_enough and absf(offset.x) < 215.0 and _attack_cooldown <= 0.0:
			facing = 1.0 if offset.x >= 0.0 else -1.0
			_phase = "warning"
			_phase_timer = 0.57
			velocity.x = 0.0
		else:
			if absf(global_position.x - _home_x) > patrol_radius:
				facing = -1.0 if global_position.x > _home_x else 1.0
			elif close_enough and absf(offset.x) > 75.0:
				facing = 1.0 if offset.x > 0.0 else -1.0
			velocity.x = move_toward(velocity.x, facing * patrol_speed, 450.0 * delta)
	# Do not charge off cliffs or walk out of the patrol arena.
	_ledge_probe.target_position = Vector2(facing * 52.0, 115.0)
	_ledge_probe.force_raycast_update()
	if is_on_floor() and (not _ledge_probe.is_colliding() or absf(global_position.x - _home_x) > patrol_radius + 85.0):
		velocity.x = 0.0
		if _phase == "charge":
			_enter_recovery()
		else:
			facing *= -1.0
	velocity.y = minf(950.0, velocity.y + 1500.0 * delta)
	move_and_slide()
	if _phase == "charge" and _contact_cooldown <= 0.0 and is_instance_valid(_player):
		offset = _player.global_position - global_position
		if offset.x * facing >= -18.0 and offset.x * facing < 73.0 and absf(offset.y) < 65.0:
			if _player.has_method("receive_enemy_hit"):
				_player.call("receive_enemy_hit", damage, global_position, 35.0)
			_contact_cooldown = 1.0
			_enter_recovery()
	if global_position.y > 1200.0:
		queue_free()
	queue_redraw()

func _enter_recovery() -> void:
	_phase = "recover"
	_phase_timer = 0.88
	_attack_cooldown = 1.65

func take_hit(amount: int, knockback: Vector2, poise_damage: float = 20.0) -> void:
	if _dead or amount <= 0:
		return
	health -= amount
	if health <= 0:
		_dead = true
		set_physics_process(false)
		collision_layer = 0
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.35)
		fade.tween_callback(queue_free)
		return
	_hurt_timer = 0.22
	if poise_damage >= 15.0:
		_enter_recovery()
		velocity = knockback * 0.2
	queue_redraw()

func _draw() -> void:
	var hide_color := Color("#4b473d")
	var mane_color := Color("#363a34")
	if _hurt_timer > 0.0:
		hide_color = Color("#ad7054")
	var leg_motion: float = sin(_clock * 13.0) * 5.0 if absf(velocity.x) > 28.0 else 0.0
	# Low, heavy body; projecting snout, bristles and unmistakable curved tusks.
	for i in range(4):
		var leg_x: float = (-22.0 + float(i) * 14.0)
		draw_line(Vector2(leg_x, 5.0), Vector2(leg_x + (leg_motion if i % 2 == 0 else -leg_motion), 26.0), mane_color, 7.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-46,-15),Vector2(-33,-31),Vector2(9,-36),Vector2(38,-24),Vector2(43,-3),Vector2(22,14),Vector2(-34,13)]), hide_color)
	for i in range(9):
		var bx: float = -24.0 + float(i) * 6.0
		draw_line(Vector2(bx,-30),Vector2(bx-7,-42.0-float(i%3)*3.0),mane_color,2.4)
	var head_x: float = 37.0 * facing
	draw_circle(Vector2(head_x, -13), 19.0, hide_color)
	draw_colored_polygon(PackedVector2Array([Vector2(45*facing,-13),Vector2(68*facing,-9),Vector2(68*facing,1),Vector2(47*facing,4)]),Color("#695b4b"))
	draw_circle(Vector2(58*facing,-8), 3.5, Color("#282b28"))
	draw_circle(Vector2(38*facing,-20), 2.5, Color("#ead8ad"))
	draw_colored_polygon(PackedVector2Array([Vector2(45*facing,-3),Vector2(52*facing,6),Vector2(59*facing,-3),Vector2(56*facing,9)]),Color("#e0cfac"))
	draw_colored_polygon(PackedVector2Array([Vector2(22*facing,-30),Vector2(25*facing,-49),Vector2(35*facing,-35)]),mane_color)
	if _phase == "warning":
		draw_arc(Vector2(34.0*facing,-12.0), 39.0, 0.0, TAU, 24, Color("#e6b06a"), 3.0)
	if _phase == "charge":
		draw_line(Vector2(-41.0*facing,-2),Vector2(-65.0*facing,0),Color("#dfc18b",0.67),3.0)
	if health < max_health and not _dead:
		var width: float = 65.0 * clampf(float(health) / float(max_health),0.0,1.0)
		draw_rect(Rect2(-33,-66,66,5),Color("#292f29"))
		draw_rect(Rect2(-33,-66,width,5),Color("#b97853"))
