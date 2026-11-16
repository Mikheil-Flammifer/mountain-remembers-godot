extends Node2D

## Old stone residential district. Cathedral entry is an E-interaction zone.

func _draw() -> void:
	draw_rect(Rect2(0, -500, 2400, 1250), Color("#a7a99f"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 450), Vector2(350, 260), Vector2(730, 460),
		Vector2(1250, 235), Vector2(1750, 445), Vector2(2400, 275),
		Vector2(2400, 650), Vector2(0, 650)
	]), Color("#66736c"))
	draw_rect(Rect2(0, 650, 2400, 170), Color("#6c6658"))
	for x: float in [80.0, 410.0, 760.0, 1180.0, 1540.0, 1960.0]:
		_draw_house(x)

	# Stone archway marking the route to the cathedral (at x = 970).
	draw_rect(Rect2(892, 435, 28, 215), Color("#898072"))
	draw_rect(Rect2(1020, 435, 28, 215), Color("#898072"))
	draw_rect(Rect2(880, 414, 180, 34), Color("#908777"))


func _draw_house(x: float) -> void:
	draw_rect(Rect2(x, 390, 240, 260), Color("#8a8578"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 15, 390), Vector2(x + 120, 318),
		Vector2(x + 255, 390)
	]), Color("#494b48"))
	draw_rect(Rect2(x + 24, 454, 34, 48), Color("#444741"))
	draw_rect(Rect2(x + 161, 460, 36, 48), Color("#444741"))
	draw_rect(Rect2(x + 102, 555, 55, 95), Color("#5a493d"))
	draw_rect(Rect2(x + 10, 522, 216, 9), Color("#655441"))
