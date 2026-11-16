extends Node2D

## Upper town: hills, stone retaining walls and wood/stone platforms.
## Real platform colliders are in terraces.tscn.

func _draw() -> void:
	draw_rect(Rect2(0, -500, 2400, 1250), Color("#a1aca6"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 500), Vector2(290, 210), Vector2(520, 440),
		Vector2(980, 150), Vector2(1290, 420), Vector2(1680, 175),
		Vector2(2100, 390), Vector2(2400, 210),
		Vector2(2400, 650), Vector2(0, 650)
	]), Color("#64756f"))
	draw_rect(Rect2(0, 650, 2400, 170), Color("#6b6354"))

	for x: float in [270.0, 750.0, 1400.0, 1940.0]:
		draw_rect(Rect2(x, 455, 310, 195), Color("#726e62"))
		for y: float in [495.0, 540.0, 590.0]:
			draw_line(Vector2(x, y), Vector2(x + 310, y), Color("#59594f"), 1)

	# Raised terraces match the platform collision nodes in the scene.
	for pos: Vector2 in [Vector2(600, 548), Vector2(1100, 495), Vector2(1590, 550)]:
		draw_rect(Rect2(pos, Vector2(210, 18)), Color("#9c9682"))
		draw_rect(Rect2(pos.x, pos.y, 210, 4), Color("#c2b39a"))
