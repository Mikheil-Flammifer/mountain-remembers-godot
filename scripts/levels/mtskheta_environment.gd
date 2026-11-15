extends Node2D
## Lightweight hand-drawn scenery for the Mtskheta prototype.
## No textures or expensive effects; everything is local to this level.

const WIDTH: float = 3600.0
const FLOOR_Y: float = 610.0

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Sky and distant ridges.
	draw_rect(Rect2(0, -900, WIDTH, 1550), Color("c4ba9d"))
	_draw_ridge(300.0, 135.0, 0.012, Color("919a92"), 0.0)
	_draw_ridge(390.0, 95.0, 0.019, Color("74837d"), 1.8)
	_draw_ridge(465.0, 62.0, 0.028, Color("536b67"), 3.5)
	# A soft river through the bottom of the image; terrain is in front.
	draw_rect(Rect2(0, 590, WIDTH, 230), Color("476b75"))
	for n in range(30):
		var x: float = float(n) * 140.0
		draw_line(Vector2(x, 687), Vector2(x + 66, 687), Color("93aaa3", 0.42), 2.0)
	# Distant silhouette of Svetitskhoveli / Mtskheta; evocative rather than architectural reconstruction.
	_draw_town(610.0, 465.0, Color("4a5450"))
	_draw_church(1045.0, 446.0, 1.35, Color("343f3e"))
	_draw_church(2860.0, 434.0, 0.8, Color("455450"))
	for x in [180.0, 420.0, 1450.0, 1700.0, 2260.0, 2370.0, 3100.0, 3390.0]:
		_draw_tree(x, 574.0, 1.0 if x < 2000.0 else 1.25)
	# Foreground terrain. Physics shapes are placed separately in the scene.
	draw_rect(Rect2(0, FLOOR_Y, WIDTH, 170), Color("273c39"))
	draw_rect(Rect2(0, FLOOR_Y, WIDTH, 12), Color("81917a"))
	for x in [800.0, 1300.0, 1980.0, 2550.0]:
		var platform_y: float = 510.0 if x != 1300.0 else 470.0
		draw_rect(Rect2(x, platform_y, 200, 24), Color("324540"))
		draw_rect(Rect2(x, platform_y, 200, 6), Color("a5a187"))
	_draw_sign(340.0, 608.0, "MTSKHETA")
	_draw_sign(2230.0, 608.0, "ROAD TO THE HIGHLANDS")


func _draw_ridge(base_y: float, amplitude: float, frequency: float, color: Color, phase: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2(0, 800))
	for index in range(73):
		var x: float = float(index) * 50.0
		var y: float = base_y - absf(sin(x * frequency + phase)) * amplitude
		y -= absf(sin(x * frequency * 2.4 + phase)) * amplitude * 0.23
		points.append(Vector2(x, y))
	points.append(Vector2(WIDTH, 800))
	draw_colored_polygon(points, color)


func _draw_town(x: float, y: float, color: Color) -> void:
	for index in range(16):
		var px: float = x + float(index) * 53.0
		var h: float = 56.0 + float((index * 17) % 64)
		draw_rect(Rect2(px, y - h, 48, h), color)
		draw_colored_polygon(PackedVector2Array([
			Vector2(px - 6, y - h), Vector2(px + 24, y - h - 23),
			Vector2(px + 54, y - h)
		]), color)


func _draw_church(x: float, y: float, scale_factor: float, color: Color) -> void:
	draw_set_transform(Vector2(x, y), 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(-62, -105, 124, 105), color)
	draw_rect(Rect2(-24, -153, 48, 48), color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-35, -153), Vector2(0, -200), Vector2(35, -153)
	]), color)
	draw_rect(Rect2(-4, -217, 8, 21), color)
	draw_rect(Rect2(-12, -211, 24, 6), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_tree(x: float, ground_y: float, scale_factor: float) -> void:
	draw_set_transform(Vector2(x, ground_y), 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(-5, -65, 10, 65), Color("263c36"))
	for tier in range(3):
		var y: float = -115.0 + float(tier) * 30.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, y - 27), Vector2(-40 + tier * 6, y + 35),
			Vector2(40 - tier * 6, y + 35)
		]), Color("2d4941"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sign(x: float, ground_y: float, text_value: String) -> void:
	draw_rect(Rect2(x - 5, ground_y - 70, 10, 70), Color("42382f"))
	draw_rect(Rect2(x - 110, ground_y - 115, 220, 48), Color("6a5845"))
	draw_string(ThemeDB.fallback_font, Vector2(x - 101, ground_y - 85), text_value,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e5d6b4"))
