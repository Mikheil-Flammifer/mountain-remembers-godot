extends Area2D

## Rare mountain healing stone. Unlike a rest shrine, it is a finite resource:
## it adds one charge and does not respawn again during the current play session.

@export var pickup_id: String = "zhinvali_stone"
@export var amount: int = 1

var _time: float = 0.0
var _taken: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	collision.position = Vector2(0.0, -26.0)
	collision.shape = shape
	add_child(collision)

	body_entered.connect(_on_body_entered)
	call_deferred("_remove_if_already_collected")
	queue_redraw()


func _remove_if_already_collected() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if (
		player != null
		and player.has_method("has_collected_healing_stone")
		and bool(player.call("has_collected_healing_stone", pickup_id))
	):
		queue_free()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	if not body.has_method("collect_healing_stone"):
		return

	var collected: bool = bool(body.call("collect_healing_stone", pickup_id))
	if not collected:
		return

	_taken = true
	monitoring = false
	var tween := create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.24)
	tween.parallel().tween_property(self, "scale", Vector2(1.55, 1.55), 0.24)
	tween.tween_callback(queue_free)


func _draw() -> void:
	var bob: float = sin(_time * 2.6) * 4.0
	var center := Vector2(0.0, -30.0 + bob)
	var glow: float = 0.13 + (sin(_time * 3.7) + 1.0) * 0.035

	draw_circle(center, 31.0, Color(0.45, 0.72, 0.62, glow))
	draw_circle(center, 20.0, Color("#415c55"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0,-22),
		center + Vector2(15,-5),
		center + Vector2(9,18),
		center + Vector2(-10,18),
		center + Vector2(-17,-4)
	]), Color("#7fa398"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0,-18),
		center + Vector2(6,-3),
		center + Vector2(2,13),
		center + Vector2(-6,-1)
	]), Color("#c7d8bd"))
	draw_line(center + Vector2(-6, -1), center + Vector2(9, 18), Color("#526c65"), 2.0)
