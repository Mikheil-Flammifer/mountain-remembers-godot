extends Area2D
## Readable ceiling rock: warning -> drop -> cooldown -> reset.
@export var damage: int = 14
@export var warning_seconds: float = 0.70
@export var ground_target_y: float = 626.0
var _player: Node2D
var _origin_y: float = 0.0
var _state: String = "idle"
var _timer: float = 0.0
var _velocity: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_origin_y = position.y
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 21.0
	col.shape = circle
	add_child(col)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	match _state:
		"idle":
			if is_instance_valid(_player) and absf(_player.global_position.x - global_position.x) < 125.0:
				_state = "warning"
				_timer = warning_seconds
		"warning":
			_timer -= delta
			if _timer <= 0.0:
				_state = "fall"
				_velocity = 70.0
		"fall":
			_velocity = minf(950.0, _velocity + 1850.0 * delta)
			position.y += _velocity * delta
			if position.y >= ground_target_y:
				position.y = ground_target_y
				_state = "spent"
				_timer = 2.7
		"spent":
			_timer -= delta
			if _timer <= 0.0:
				_state = "idle"
				position.y = _origin_y
				_velocity = 0.0
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _state == "fall" and body.is_in_group("player") and body.has_method("receive_enemy_hit"):
		body.call("receive_enemy_hit", damage, global_position, 26.0)

func _draw() -> void:
	if _state == "warning":
		draw_line(Vector2(0,10), Vector2(0, GROUND_TARGET()), Color("#e6a46d",0.75), 3.0)
		draw_arc(Vector2(0, GROUND_TARGET()), 26.0, 0, TAU, 24, Color("#edbd86"), 3.0)
	if _state == "spent":
		return
	draw_colored_polygon(PackedVector2Array([Vector2(-23,-12),Vector2(-4,-23),Vector2(20,-17),Vector2(27,12),Vector2(2,24),Vector2(-25,12)]),Color("#6f6d59"))
	draw_line(Vector2(-14,-10),Vector2(5,-18),Color("#b0a78b"),3.0)

func GROUND_TARGET() -> float:
	return ground_target_y - position.y
