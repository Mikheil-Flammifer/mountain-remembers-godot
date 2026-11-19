class_name MountainWolf
extends CharacterBody2D

## Aggressive wolf: quick readable bite, poise-based interruptions.
## standing nearby no longer causes instant or repeated contact damage.
enum State { PATROL, CHASE, WINDUP, BITE, RECOVERY, HURT, DEAD }

@export_group("Attack")
@export var attack_damage: int = 8
@export var attack_range: float = 96.0
@export var bite_reach: float = 112.0
@export var bite_height: float = 48.0
@export var windup_duration: float = 0.20
@export var bite_duration: float = 0.22
@export var recovery_duration: float = 0.24
@export var attack_cooldown: float = 0.30
@export_group("Movement")
@export var patrol_speed: float = 65.0
@export var chase_speed: float = 130.0
@export var acceleration: float = 700.0
@export var gravity: float = 1200.0
@export_group("Detection")
@export var detection_range: float = 285.0
@export var lose_range: float = 430.0
@export var detection_height: float = 105.0
@export var stop_distance: float = 45.0
@export_group("Health")
@export var max_health: int = 35
@export var hurt_duration: float = 0.30
@export_group("Poise")
@export var max_poise: float = 18.0
@export var poise_recovery_delay: float = 1.4
@export var poise_recovery_per_second: float = 15.0
@export var bite_poise_damage: float = 28.0

@onready var visual: Polygon2D = $Visual
@onready var floor_ray: RayCast2D = $FloorAhead
@onready var wall_ray: RayCast2D = $WallAhead

var state: State = State.PATROL
var health: int = 0
var facing: int = -1
var player: Node2D
var dead: bool = false
var poise: float = 18.0
var _poise_delay: float = 0.0
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _bit_this_attack: bool = false
var _home_position: Vector2
var _patrol_distance: float = 160.0
var _health_ui: VBoxContainer
var _health_bar: ProgressBar
var _health_label: Label

func _ready() -> void:
	health = max_health
	poise = max_poise
	_home_position = global_position
	_update_rays()
	_build_health_bar()
	_update_health_bar()
	player = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if dead:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_poise_delay = maxf(0.0, _poise_delay - delta)
	if _poise_delay <= 0.0:
		poise = minf(max_poise, poise + poise_recovery_per_second * delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 900.0)
	match state:
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase(delta)
		State.WINDUP:
			_brake(delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_enter_state(State.BITE, bite_duration)
				_bit_this_attack = false
		State.BITE:
			_brake(delta)
			_state_timer -= delta
			_try_bite()
			if _state_timer <= 0.0:
				_enter_state(State.RECOVERY, recovery_duration)
		State.RECOVERY:
			_brake(delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_enter_state(State.CHASE if _can_detect_player() else State.PATROL)
		State.HURT:
			_state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
			if _state_timer <= 0.0:
				_enter_state(State.CHASE if _can_detect_player() else State.PATROL)
	move_and_slide()
	_update_visual()
	# Only redraw the warning during the short attack animation.
	if state in [State.WINDUP, State.BITE]:
		queue_redraw()

func _enter_state(next: State, duration: float = 0.0) -> void:
	state = next
	_state_timer = duration
	queue_redraw()

func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 1.8 * delta)

func _patrol(delta: float) -> void:
	if _can_detect_player():
		_enter_state(State.CHASE)
		return
	if _should_turn():
		_turn()
	if absf(global_position.x - _home_position.x) > _patrol_distance:
		if (global_position.x > _home_position.x and facing > 0) or (global_position.x < _home_position.x and facing < 0):
			_turn()
	velocity.x = move_toward(velocity.x, facing * patrol_speed, acceleration * delta)

func _chase(delta: float) -> void:
	if not _get_player():
		_enter_state(State.PATROL)
		return
	var offset: Vector2 = player.global_position - global_position
	if offset.length() > lose_range:
		_enter_state(State.PATROL)
		return
	if absf(offset.x) <= attack_range and absf(offset.y) <= bite_height + 18.0 and _attack_timer <= 0.0 and is_on_floor():
		# The facing direction is committed before warning starts.
		_set_facing(1 if offset.x >= 0.0 else -1)
		_enter_state(State.WINDUP, windup_duration)
		_brake(delta)
		return
	if absf(offset.x) > stop_distance:
		_set_facing(1 if offset.x > 0.0 else -1)
		if _should_turn():
			_brake(delta)
			return
		velocity.x = move_toward(velocity.x, facing * chase_speed, acceleration * delta)
	else:
		_brake(delta)

func _try_bite() -> void:
	if _bit_this_attack or not _get_player() or not player.has_method("receive_enemy_hit"):
		return
	var difference: Vector2 = player.global_position - global_position
	# No bite from behind; airborne players above the bite safely avoid it.
	if difference.x * float(facing) < -4.0 or difference.x * float(facing) > bite_reach:
		return
	if absf(difference.y) > bite_height:
		return
	_bit_this_attack = true
	_attack_timer = attack_cooldown
	player.call("receive_enemy_hit", attack_damage, global_position, bite_poise_damage)

func _get_player() -> bool:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	return is_instance_valid(player)

func _can_detect_player() -> bool:
	if not _get_player():
		return false
	var difference: Vector2 = player.global_position - global_position
	return absf(difference.x) <= detection_range and absf(difference.y) <= detection_height

func _should_turn() -> bool:
	if not is_on_floor():
		return false
	floor_ray.force_raycast_update()
	wall_ray.force_raycast_update()
	return not floor_ray.is_colliding() or wall_ray.is_colliding()

func _turn() -> void:
	_set_facing(-facing)

func _set_facing(next_facing: int) -> void:
	if facing == next_facing:
		return
	facing = next_facing
	_update_rays()

func _update_rays() -> void:
	floor_ray.position = Vector2(30.0 * facing, 0.0)
	floor_ray.target_position = Vector2(0.0, 58.0)
	wall_ray.position = Vector2(0.0, -5.0)
	wall_ray.target_position = Vector2(32.0 * facing, 0.0)

func _update_visual() -> void:
	visual.scale.x = float(facing)
	match state:
		State.WINDUP:
			visual.modulate = Color(1.25, 0.77, 0.55)
		State.BITE:
			visual.modulate = Color(1.30, 0.42, 0.39)
		State.HURT:
			visual.modulate = Color(1.0, 0.35, 0.35)
		State.RECOVERY:
			visual.modulate = Color(0.62, 0.68, 0.74)
		State.CHASE:
			visual.modulate = Color(0.78, 0.80, 0.83)
		_:
			visual.modulate = Color.WHITE

func _draw() -> void:
	if state == State.WINDUP:
		# A recognizable warning on the ground, visible for ~0.5 seconds.
		var warning := Color(0.96, 0.56, 0.29, 0.80)
		draw_arc(Vector2(43.0 * facing, 14.0), 35.0, 0.0, TAU, 28, warning, 3.0)
		draw_line(Vector2(10.0 * facing, 32.0), Vector2(85.0 * facing, 32.0), warning, 4.0)
	elif state == State.BITE:
		draw_line(Vector2(2.0 * facing, -13.0), Vector2(88.0 * facing, -19.0), Color(1.0, 0.76, 0.55, 0.90), 7.0)

func take_hit(amount: int, knockback: Vector2, poise_damage: float = 20.0) -> void:
	if dead or amount <= 0:
		return
	health = maxi(health - amount, 0)
	_update_health_bar()
	if health <= 0:
		_die()
		return
	poise = maxf(0.0, poise - poise_damage)
	_poise_delay = poise_recovery_delay
	# Only a poise break interrupts a committed wolf attack.
	if poise <= 0.0:
		poise = max_poise
		_enter_state(State.HURT, hurt_duration)
		_attack_timer = maxf(_attack_timer, 0.25)
		velocity = Vector2(knockback.x * 0.45, minf(knockback.y, -60.0))

func _die() -> void:
	dead = true
	_enter_state(State.DEAD)
	velocity = Vector2.ZERO
	if _health_ui != null:
		_health_ui.hide()
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.45)
	tween.tween_callback(queue_free)

func _build_health_bar() -> void:
	_health_ui = VBoxContainer.new()
	_health_ui.name = "EnemyHealthUI"
	_health_ui.position = Vector2(-55.0, -87.0)
	_health_ui.custom_minimum_size = Vector2(110.0, 35.0)
	_health_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health_ui.add_theme_constant_override("separation", 2)
	add_child(_health_ui)
	_health_label = Label.new()
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health_label.add_theme_font_size_override("font_size", 12)
	_health_label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.78))
	_health_ui.add_child(_health_label)
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(110.0, 12.0)
	_health_bar.min_value = 0
	_health_bar.max_value = max_health
	_health_bar.show_percentage = false
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.12, 0.12, 0.14, 0.9)
	background.border_color = Color(0.38, 0.34, 0.30)
	background.set_border_width_all(1)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.72, 0.19, 0.14)
	_health_bar.add_theme_stylebox_override("background", background)
	_health_bar.add_theme_stylebox_override("fill", fill)
	_health_ui.add_child(_health_bar)

func _update_health_bar() -> void:
	if _health_bar == null:
		return
	_health_bar.max_value = maxi(max_health, 1)
	_health_bar.value = health
	_health_label.text = "%d / %d" % [health, max_health]
