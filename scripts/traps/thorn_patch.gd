extends Area2D
## Reusable visible ground trap; Area collision shape in its scene.
@export var damage: int = 12

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("receive_enemy_hit"):
		body.call("receive_enemy_hit", damage, global_position)

func _draw() -> void:
	draw_rect(Rect2(-48, 6, 96, 7), Color("#633e2b"))
	for i: int in range(7):
		var x: float = -42.0 + float(i) * 14.0
		var tip: float = -34.0 if i % 2 == 0 else -26.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 7.0, 8), Vector2(x, tip), Vector2(x + 7.0, 8)
		]), Color("#51322b"))
		draw_line(Vector2(x, tip + 7), Vector2(x, 5), Color("#ca895b"), 1.5)
