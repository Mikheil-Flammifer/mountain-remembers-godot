extends Area2D
## Reusable mountain ladder. The node origin sits on the LOWER walking surface.
## ladder_height is the vertical distance to the UPPER walking surface.

@export var ladder_height: float = 260.0
@export var climb_speed: float = 205.0
@export var player_half_height: float = 48.0
@export var snap_speed: float = 14.0
@export var show_prompt: bool = true

var _player: XizanePlayer
var _climbing: bool = false
var _prompt: Label
var _clock: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	_build_sensor()
	_build_prompt()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _build_sensor() -> void:
	var sensor := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(86.0, ladder_height + 112.0)
	sensor.shape = rect
	sensor.position = Vector2(0.0, -ladder_height * 0.5 - player_half_height)
	add_child(sensor)


func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.text = "W / S  -  Climb"
	_prompt.position = Vector2(-92.0, -112.0)
	_prompt.size = Vector2(184.0, 30.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 15)
	_prompt.add_theme_color_override("font_color", Color("#f2ddb1"))
	_prompt.add_theme_color_override("font_outline_color", Color("#29322d"))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	add_child(_prompt)


func _physics_process(delta: float) -> void:
	_clock += delta
	if not _climbing:
		if is_instance_valid(_player):
			var axis := _vertical_axis()
			if not is_zero_approx(axis):
				_start_climb()
		return

	if not is_instance_valid(_player):
		_climbing = false
		return

	if _player.health.is_dead:
		_finish_climb(Vector2.ZERO)
		_player = null
		return

	if Input.is_action_just_pressed("jump"):
		var side: float = Input.get_axis("move_left", "move_right")
		_finish_climb(Vector2(side * 235.0, -365.0))
		return

	var axis: float = _vertical_axis()
	var target_x: float = global_position.x
	var snap_alpha: float = clampf(snap_speed * delta, 0.0, 1.0)
	_player.global_position.x = lerpf(_player.global_position.x, target_x, snap_alpha)
	_player.velocity = Vector2(0.0, axis * climb_speed)
	_player.global_position.y += axis * climb_speed * delta

	var top_origin_y: float = global_position.y - ladder_height - player_half_height
	var bottom_origin_y: float = global_position.y - player_half_height
	_player.global_position.y = clampf(_player.global_position.y, top_origin_y, bottom_origin_y)
	_player.set_ladder_climb_phase(_clock * 8.0 if not is_zero_approx(axis) else 0.0)

	if axis < 0.0 and _player.global_position.y <= top_origin_y + 2.0:
		_player.global_position.y = top_origin_y
		_finish_climb(Vector2.ZERO)
	elif axis > 0.0 and _player.global_position.y >= bottom_origin_y - 2.0:
		_player.global_position.y = bottom_origin_y
		_finish_climb(Vector2.ZERO)


func _process(_delta: float) -> void:
	if not is_instance_valid(_prompt):
		return
	if is_instance_valid(_player):
		_prompt.position.y = to_local(_player.global_position).y - 92.0
	_prompt.visible = show_prompt and is_instance_valid(_player) and not _climbing


func _vertical_axis() -> float:
	var up: bool = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var down: bool = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	if up == down:
		return 0.0
	return -1.0 if up else 1.0


func _start_climb() -> void:
	if not is_instance_valid(_player) or _climbing or not _player.begin_ladder_climb():
		return
	_climbing = true
	_prompt.visible = false


func _finish_climb(launch_velocity: Vector2) -> void:
	_climbing = false
	if is_instance_valid(_player):
		_player.end_ladder_climb(launch_velocity)
	if is_instance_valid(_prompt):
		_prompt.visible = true


func _on_body_entered(body: Node2D) -> void:
	if body is XizanePlayer:
		_player = body


func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	if _climbing:
		_finish_climb(Vector2.ZERO)
	_player = null
	if is_instance_valid(_prompt):
		_prompt.visible = false


func _draw() -> void:
	var rail_color := Color("#5b4935")
	var rail_light := Color("#8b6d49")
	var rung_color := Color("#75583b")
	var top_y: float = -ladder_height

	# Rough timber side rails.
	draw_line(Vector2(-21.0, 4.0), Vector2(-18.0, top_y - 9.0), rail_color, 9.0)
	draw_line(Vector2(21.0, 4.0), Vector2(18.0, top_y - 9.0), rail_color, 9.0)
	draw_line(Vector2(-18.0, 0.0), Vector2(-16.0, top_y - 7.0), rail_light, 2.0)
	draw_line(Vector2(20.0, 0.0), Vector2(17.0, top_y - 7.0), rail_light, 2.0)

	var rung_count: int = maxi(2, floori(ladder_height / 31.0))
	for i in range(rung_count + 1):
		var y: float = -10.0 - float(i) * ladder_height / float(rung_count)
		draw_line(Vector2(-23.0, y), Vector2(23.0, y + 1.5), Color("#3c3128"), 7.0)
		draw_line(Vector2(-20.0, y - 2.0), Vector2(20.0, y - 0.5), rung_color, 4.0)
