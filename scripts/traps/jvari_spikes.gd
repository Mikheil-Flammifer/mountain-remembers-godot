extends Area2D
## Surface thorn clusters: collision damage with the existing invulnerability window.
@export var damage: int = 12

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(102, 35)
	collider.shape = rect
	collider.position = Vector2(0, -11)
	add_child(collider)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("receive_enemy_hit"):
		body.call("receive_enemy_hit", damage, global_position, 20.0)

func _draw() -> void:
	draw_rect(Rect2(-53, -1, 106, 8), Color("#604b3d"))
	for i in range(8):
		var x: float = -49 + float(i) * 14.0
		var h: float = 29.0 if i % 2 == 0 else 38.0
		draw_colored_polygon(PackedVector2Array([Vector2(x-7,0),Vector2(x,-h),Vector2(x+7,0)]),Color("#443b36"))
		draw_line(Vector2(x,-h+8),Vector2(x,0),Color("#bd8056"),1.1)
