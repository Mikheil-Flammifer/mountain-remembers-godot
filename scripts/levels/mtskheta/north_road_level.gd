extends Node2D

## Wilderness transition beyond Mtskheta. Wolf encounter lives here.

func _draw() -> void:
	draw_rect(Rect2(0, -500, 2400, 1250), Color("#9ca9a4"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 440), Vector2(380, 105), Vector2(680, 420),
		Vector2(1160, 70), Vector2(1500, 410), Vector2(2020, 125),
		Vector2(2400, 400), Vector2(2400, 650), Vector2(0, 650)
	]), Color("#627772"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 540), Vector2(360, 370), Vector2(790, 545),
		Vector2(1370, 340), Vector2(1780, 535), Vector2(2300, 310),
		Vector2(2400, 390), Vector2(2400, 650), Vector2(0, 650)
	]), Color("#40574f"))
	draw_rect(Rect2(0, 650, 2400, 170), Color("#665e50"))

	for x: float in [250.0, 520.0, 840.0, 1450.0, 1730.0, 2070.0]:
		_draw_tree(x)

	# Wooden northern road marker.
	draw_rect(Rect2(430, 520, 13, 130), Color("#574535"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(384, 526), Vector2(476, 526),
		Vector2(500, 545), Vector2(476, 565), Vector2(384, 565)
	]), Color("#826b4e"))


func _draw_tree(x: float) -> void:
	draw_rect(Rect2(x - 8, 490, 16, 160), Color("#4f4438"))
	draw_circle(Vector2(x, 462), 65, Color("#334940"))
	draw_circle(Vector2(x - 40, 490), 43, Color("#334940"))
	draw_circle(Vector2(x + 44, 488), 43, Color("#334940"))
