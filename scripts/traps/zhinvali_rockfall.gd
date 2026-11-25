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
		var pulse: float = 0.24 + 0.18 * sin(_timer * 13.0)
		for i in range(5):
			var px: float = -44.0 + float(i) * 22.0
			var py: float = -116.0 + float(i % 2) * 12.0 + pulse * 18.0
			draw_circle(Vector2(px, py), 4.0 + float(i % 2), Color("#9a927f", 0.65))
			draw_line(Vector2(px, py + 5.0), Vector2(px - 4.0, py + 14.0), Color("#c7b491", 0.30), 1.0)
		# Dust on the ground instead of an artificial trajectory guide.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-82.0, -1.0), Vector2(-48.0, -9.0), Vector2(-10.0, -6.0), Vector2(32.0, -11.0), Vector2(84.0, -2.0), Vector2(82.0, 3.0), Vector2(-82.0, 3.0)
		]), Color("#ad9070", 0.26))
	elif _state == "falling":
		var y: float = lerpf(-370.0, -22.0, _fall_progress * _fall_progress)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-54.0,y),Vector2(-30.0,y-28.0),Vector2(10.0,y-38.0),
			Vector2(50.0,y-18.0),Vector2(44.0,y+20.0),Vector2(14.0,y+30.0),Vector2(-32.0,y+24.0)
		]),Color("#696e67"))
		draw_line(Vector2(-22.0,y-18.0),Vector2(8.0,y-29.0),Color("#b0ad98"),2.6)
		for i in range(4):
			var px: float = -28.0 + float(i) * 18.0
			draw_circle(Vector2(px, y + 34.0 + float(i % 2) * 4.0), 3.0, Color("#8f8a79", 0.74))
	elif _state == "cooldown":
		for poly in [
			PackedVector2Array([Vector2(-28.0,-2.0),Vector2(-18.0,-10.0),Vector2(-4.0,-4.0),Vector2(-10.0,2.0)]),
			PackedVector2Array([Vector2(6.0,-4.0),Vector2(20.0,-12.0),Vector2(28.0,-2.0),Vector2(14.0,2.0)]),
			PackedVector2Array([Vector2(32.0,-1.0),Vector2(42.0,-8.0),Vector2(52.0,-2.0),Vector2(42.0,3.0)])
		]:
			draw_colored_polygon(poly, Color("#8e8674", 0.46))
