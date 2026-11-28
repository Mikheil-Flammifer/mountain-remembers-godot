extends Area2D
## Unstable ground: the level owns the recovery and quest state.
signal touched(body: Node2D)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(54, 12)
	collider.shape = shape
	collider.position.y = -6
	add_child(collider)
	body_entered.connect(func(body: Node2D) -> void: touched.emit(body))

func _draw() -> void:
	# A conspicuous cracked patch; the collision footprint matches the artwork.
	draw_rect(Rect2(-27, -12, 54, 12), Color("#806d52"))
	for x in [-23.0, -9.0, 5.0, 19.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 0), Vector2(x, -20), Vector2(x + 7, 0)]), Color("#c5aa7c"))
	draw_line(Vector2(-25, -3), Vector2(25, -3), Color("#3c3830"), 2.0)
