extends StaticBody2D
## Reusable low goods stand with solid countertop/crates. Jumpable.

func _draw() -> void:
	var dark := Color("#533929")
	var wood := Color("#98704b")
	var light := Color("#c19a68")
	draw_rect(Rect2(-60, -42, 120, 14), dark)
	draw_rect(Rect2(-57, -40, 114, 8), light)
	draw_rect(Rect2(-52, -28, 104, 28), wood)
	for x: float in [-46.0, 42.0]:
		draw_line(Vector2(x, -27), Vector2(x, 0), dark, 8)
	for x: float in [-36.0, -12.0, 14.0, 38.0]:
		draw_circle(Vector2(x, -50), 12.0, Color("#a7763d"))
		draw_circle(Vector2(x - 3, -54), 3.0, Color("#d7b16e"))
