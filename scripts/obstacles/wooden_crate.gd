extends StaticBody2D
## Reusable 62x66 solid market crate, origin at centre.

func _draw() -> void:
	draw_rect(Rect2(-31, -33, 62, 66), Color("#75513a"))
	draw_rect(Rect2(-29, -31, 58, 62), Color("#a17850"))
	draw_rect(Rect2(-26, -28, 52, 56), Color("#67452f"), false, 4.0)
	draw_line(Vector2(-25, -26), Vector2(25, 26), Color("#e0ba7e"), 4.0)
	draw_line(Vector2(25, -26), Vector2(-25, 26), Color("#533629"), 4.0)
	for y: float in [-18.0, 12.0]:
		draw_line(Vector2(-28, y), Vector2(28, y), Color("#b68e61"), 2.0)
	for x: float in [-23.0, 23.0]:
		for y: float in [-24.0, 24.0]:
			draw_circle(Vector2(x, y), 2.5, Color("#d6b57b"))
