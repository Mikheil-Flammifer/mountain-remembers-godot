extends Area2D
## Oscillating wind. Strong during the visible gust, silent during respite.
@export var force: float = 540.0
@export var direction: float = -1.0
var _clock: float = 0.0
var _active: bool = false
var _player: CharacterBody2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var area := RectangleShape2D.new()
	area.size = Vector2(280, 194)
	shape.shape = area
	add_child(shape)
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)

func _physics_process(delta: float) -> void:
	_clock += delta
	_active = fposmod(_clock, 3.4) < 2.0
	if _active and is_instance_valid(_player):
		_player.velocity.x += direction * force * delta
	queue_redraw()

func _on_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body as CharacterBody2D

func _on_exited(body: Node2D) -> void:
	if body == _player:
		_player = null

func _draw() -> void:
	var tint: Color = Color("#b1cbbb", 0.67 if _active else 0.16)
	for i in range(7):
		var y: float = -79.0 + float(i) * 25.0
		var wobble: float = sin(_clock * 5.0 + float(i)) * 15.0
		draw_line(Vector2(-115.0 + wobble, y),Vector2(95.0 + wobble, y - 7),tint,2.0)
		var sx: float = 95.0 if direction > 0 else -115.0
		draw_line(Vector2(sx, y - 7),Vector2(sx - direction * 12.0, y - 15),tint,2.0)
