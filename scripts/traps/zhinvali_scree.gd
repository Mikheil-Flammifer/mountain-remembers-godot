extends Area2D
## Unstable scree: a readable falling-stone warning when sprinting over a slope.
@export var damage: int = 5
@export var warning_seconds: float = 0.56
var _player: CharacterBody2D
var _delay: float = 0.0
var _cooldown: float = 0.0
var _clock: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(235.0, 128.0)
	shape.position = Vector2(0.0, -56.0)
	shape.shape = rectangle
	add_child(shape)
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)

func _on_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body as CharacterBody2D
		if _cooldown <= 0.0 and absf(_player.velocity.x) > 65.0:
			_delay = warning_seconds

func _on_exited(body: Node2D) -> void:
	if body == _player:
		_player = null

func _physics_process(delta: float) -> void:
	_clock += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if _delay > 0.0:
		_delay -= delta
		if _delay <= 0.0 and is_instance_valid(_player):
			if _player.has_method("receive_enemy_hit"):
				_player.call("receive_enemy_hit", damage, global_position, 9.0)
			_cooldown = 3.0
	queue_redraw()

func _draw() -> void:
	for i in range(18):
		var x: float = -110.0 + float(i) * 13.0
		var yy: float = float(i % 3) * 4.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x-8.0,-2.0),Vector2(x+2.0,-11.0-yy),Vector2(x+13.0,1.0)
		]), Color("#929181", 0.9) if i % 2 == 0 else Color("#6d7369"))
	if _delay > 0.0:
		draw_line(Vector2(-110.0,-19.0),Vector2(110.0,-19.0),Color("#e6b16d",0.45 + sin(_clock * 17.0)*0.30),3.0)
