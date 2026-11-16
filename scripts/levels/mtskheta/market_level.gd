extends Node2D

## First-pass placeholder silhouettes for the Market district.
## Replace these drawings with reusable art scenes later.

func _draw() -> void:
	draw_rect(Rect2(0, -500, 2400, 1250), Color("#b8aca0"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 470), Vector2(280, 280), Vector2(610, 460),
		Vector2(1040, 240), Vector2(1520, 475), Vector2(1970, 270),
		Vector2(2400, 430), Vector2(2400, 650), Vector2(0, 650)
	]), Color("#7a7a73"))
	draw_rect(Rect2(0, 650, 2400, 170), Color("#686052"))

	for x: float in [140.0, 570.0, 1030.0, 1600.0, 2070.0]:
		_draw_stone_house(x)

	for x: float in [350.0, 820.0, 1430.0, 1860.0]:
		_draw_stall(x)


func _draw_stone_house(x: float) -> void:
	draw_rect(Rect2(x, 422, 210, 228), Color("#8b8172"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 18, 422), Vector2(x + 105, 347),
		Vector2(x + 228, 422)
	]), Color("#554c45"))
	draw_rect(Rect2(x + 40, 485, 35, 52), Color("#35383a"))
	draw_rect(Rect2(x + 135, 550, 43, 100), Color("#4a4038"))


func _draw_stall(x: float) -> void:
	draw_line(Vector2(x, 650), Vector2(x, 520), Color("#4d4035"), 9)
	draw_line(Vector2(x + 170, 650), Vector2(x + 170, 520), Color("#4d4035"), 9)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 20, 525), Vector2(x + 35, 470),
		Vector2(x + 145, 470), Vector2(x + 195, 525)
	]), Color("#76544a"))
	draw_rect(Rect2(x + 10, 585, 150, 15), Color("#68513d"))
	for basket_x: float in [40.0, 85.0, 130.0]:
		draw_circle(Vector2(x + basket_x, 579), 14, Color("#a18a5e"))
