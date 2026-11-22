extends Area2D
## Telegraph -> falling boulder -> cooldown. Uses Xizane's existing enemy-hit API.
@export var damage: int = 12
@export var warning_time: float = 0.95
@export var cooldown: float = 3.8

var _player: CharacterBody2D
var _state: String = "idle"
var _timer: float = 0.0
var _fall_progress: float = 0.0
var _hit: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var sensor := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(210.0, 210.0)
	sensor.position = Vector2(0.0, -105.0)
	sensor.shape = shape
	add_child(sensor)
	body_entered.connect(_on_enter)

func _on_enter(body: Node2D) -> void:
	if body.is_in_group("player") and _state == "idle":
		_player = body as CharacterBody2D
		_state = "warning"
		_timer = warning_time

func _physics_process(delta: float) -> void:
	if _state == "idle":
		return
	_timer -= delta
	if _state == "warning" and _timer <= 0.0:
		_state = "falling"
		_fall_progress = 0.0
		_hit = false
	elif _state == "falling":
		_fall_progress = minf(1.0, _fall_progress + delta * 2.1)
		if _fall_progress >= 0.80 and not _hit and is_instance_valid(_player):
			if absf(_player.global_position.x - global_position.x) < 73.0 and absf(_player.global_position.y + 48.0 - global_position.y) < 95.0:
				if _player.has_method("receive_enemy_hit"):
					_player.call("receive_enemy_hit", damage, global_position, 26.0)
			_hit = true
		if _fall_progress >= 1.0:
			_state = "cooldown"
			_timer = cooldown
	elif _state == "cooldown" and _timer <= 0.0:
		_state = "idle"
		if is_instance_valid(_player) and absf(_player.global_position.x - global_position.x) < 105.0:
			_state = "warning"
			_timer = warning_time
	queue_redraw()

func _draw() -> void:
	if _state == "warning":
		var pulse: float = 0.35 + 0.25 * sin(_timer * 15.0)
		draw_rect(Rect2(-76.0, -7.0, 152.0, 6.0), Color("#d49a62", pulse))
		draw_arc(Vector2(0.0, -50.0), 58.0, PI, TAU, 20, Color("#e9c08b", 0.6), 4.0)
	elif _state == "falling":
		var y: float = lerpf(-370.0, -25.0, _fall_progress * _fall_progress)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-48.0,y),Vector2(-26.0,y-24.0),Vector2(18.0,y-34.0),
			Vector2(48.0,y-12.0),Vector2(39.0,y+26.0),Vector2(-30.0,y+26.0)
		]),Color("#687068"))
		draw_line(Vector2(-19.0,y-18.0),Vector2(13.0,y-27.0),Color("#b2b3a0"),3.0)
	elif _state == "cooldown":
		for i in range(4):
			var x: float = -37.0 + float(i) * 26.0
			draw_line(Vector2(x,-4.0),Vector2(x+17.0,-3.0),Color("#a69d88",0.42),2.0)
