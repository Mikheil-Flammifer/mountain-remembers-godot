extends Node2D
# SHARED_WARM_GREEN_LANDSCAPE
const Landscape = preload("res://scripts/levels/mtskheta/shared/mtskheta_landscape.gd")
## Side-on, layered medieval Georgian market. Purely visual: no collisions or exits.
## Behind NPCs (-2) and Xizane (0).

const SKY = Color("#d5b99a")
const DISTANT = Color("#aa9077")
const MOUNTAIN = Color("#8b8067")
const STONE = Color("#ae9174")
const MORTAR = Color("#806b58")
const TIMBER = Color("#51443b")
const AWNING = Color("#84624d")
const AWNING_LIGHT = Color("#bb9a74")
const GROUND = Color("#79634d")

func _ready() -> void:
	z_index = -10
	queue_redraw()

func _draw() -> void:
	_draw_landscape()
	_draw_distant_town()
	_draw_stone_paving()
	# Buildings frame the market; the square itself stays open around the player.
	_draw_house(75.0, 270.0, 365.0)
	_draw_house(1840.0, 385.0, 370.0)
	for item: Dictionary in [
		{"x": 320.0, "w": 220.0, "type": 0},
		{"x": 715.0, "w": 220.0, "type": 1},
		{"x": 1390.0, "w": 240.0, "type": 2},
		{"x": 1730.0, "w": 195.0, "type": 3},
	]:
		_draw_stall(float(item["x"]), float(item["w"]), int(item["type"]))
	_draw_trade_carts()
	_draw_market_sign()

func _draw_landscape() -> void:
	Landscape.draw_landscape(self, 2400.0, 650.0, 0.1)
	# Jvari remains a distant landmark, not a generic fortification.
	Landscape.draw_jvari(self, 690.0, 350.0, 0.83)

func _draw_distant_town() -> void:
	for i: int in range(14):
		var x: float = float(i) * 179.0 + 12.0
		var y: float = 486.0 + float(i % 3) * 13.0
		var w: float = 128.0 + float(i % 4) * 12.0
		draw_rect(Rect2(x, y, w, 153.0), Color("#756f64"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 10, y), Vector2(x + w * 0.5, y - 54),
			Vector2(x + w + 10, y)
		]), Color("#544d46"))
		for k: int in range(2):
			draw_rect(Rect2(x + 20 + k * 49, y + 42, 17, 23), Color("#454646"))

func _draw_stone_paving() -> void:
	draw_rect(Rect2(0, 636, 2400, 184), GROUND)
	draw_rect(Rect2(0, 630, 2400, 12), Color("#9a8b76"))
	for row: int in range(6):
		var yy: float = 654.0 + row * 25.0
		draw_line(Vector2(0, yy), Vector2(2400, yy), Color("#4e4842"), 1.0)
		for i: int in range(36):
			var xx: float = i * 73.0 + (36.0 if row % 2 == 0 else 0.0)
			draw_line(Vector2(xx, yy), Vector2(xx + 4, yy + 24), Color("#4d4740"), 1.0)

func _draw_house(x: float, w: float, y: float) -> void:
	var h: float = 650.0 - y
	draw_rect(Rect2(x, y, w, h), STONE)
	for row: int in range(8):
		var yy: float = y + row * 37.0
		draw_line(Vector2(x, yy), Vector2(x + w, yy), MORTAR, 1.0)
		for i: int in range(7):
			var xx: float = x + i * 56.0 + (25.0 if row % 2 == 0 else 0.0)
			if xx < x + w:
				draw_line(Vector2(xx, yy), Vector2(xx, minf(yy + 35, 650)), MORTAR, 1.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 15, y + 5), Vector2(x + w * 0.5, y - 72),
		Vector2(x + w + 15, y + 5)
	]), Color("#55463e"))
	draw_rect(Rect2(x + w * 0.30, 525, 64, 125), Color("#403b36"))
	for k: int in range(2):
		var xx: float = x + 50.0 + k * 115.0
		draw_rect(Rect2(xx, y + 70, 42, 59), Color("#494641"))
		draw_line(Vector2(xx - 3, y + 67), Vector2(xx + 45, y + 67), Color("#b0a08d"), 5.0)

func _draw_tower(x: float) -> void:
	draw_rect(Rect2(x, 295, 140, 355), Color("#766e63"))
	for j: int in range(7):
		draw_line(Vector2(x, 334 + j * 43), Vector2(x + 140, 334 + j * 43), MORTAR, 1.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 14, 302), Vector2(x + 70, 225), Vector2(x + 154, 302)
	]), Color("#493e38"))
	draw_rect(Rect2(x + 55, 363, 27, 64), Color("#393b3b"))

func _draw_stall(x: float, w: float, goods: int) -> void:
	var canopy_y: float = 463.0 + float(goods % 2) * 12.0
	var post := Color("#4b3a30")
	draw_line(Vector2(x + 15, 647), Vector2(x + 15, canopy_y), post, 9.0)
	draw_line(Vector2(x + w - 15, 647), Vector2(x + w - 15, canopy_y), post, 9.0)
	# Linen awning with alternating faded panels and a hanging scalloped edge.
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 18, canopy_y + 32), Vector2(x + 20, canopy_y - 17),
		Vector2(x + w - 18, canopy_y - 17), Vector2(x + w + 18, canopy_y + 32)
	]), AWNING)
	for i: int in range(5):
		var left: float = x - 13 + i * (w + 26.0) / 5.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(left, canopy_y + 31), Vector2(left + 8, canopy_y - 16),
			Vector2(left + (w + 26.0) / 5.0 - 7, canopy_y - 16),
			Vector2(left + (w + 26.0) / 5.0, canopy_y + 31)
		]), AWNING_LIGHT if i % 2 == 0 else Color("#735142"))
		draw_circle(Vector2(left + 10, canopy_y + 32), 6.0, Color("#6b4c3f"))
	draw_rect(Rect2(x + 3, 562, w - 6, 16), TIMBER)
	draw_rect(Rect2(x + 13, 580, w - 26, 60), Color("#745846"))
	draw_line(Vector2(x + 18, 579), Vector2(x + w - 18, 579), Color("#ae8864"), 3)
	for k: int in range(4):
		var gx: float = x + 33 + k * (w - 55) / 3.0
		match goods:
			0: # Bread and grain
				draw_colored_polygon(PackedVector2Array([
					Vector2(gx - 17, 558), Vector2(gx - 13, 540),
					Vector2(gx + 8, 537), Vector2(gx + 17, 558)
				]), Color("#c6a16a"))
			1: # Fruit baskets
				draw_circle(Vector2(gx, 550), 13, Color("#965f42"))
				draw_circle(Vector2(gx - 8, 544), 9, Color("#b18a4b"))
			2: # Earthenware
				draw_rect(Rect2(gx - 9, 538, 20, 25), Color("#9f795e"))
				draw_circle(Vector2(gx + 1, 538), 12, Color("#a88669"))
			_: # Fabric rolls
				draw_rect(Rect2(gx - 18, 541, 33, 16), Color("#5c7470" if k % 2 == 0 else "#ac8d6d"))

func _draw_trade_carts() -> void:
	var x: float = 1120.0
	draw_rect(Rect2(x, 588, 125, 24), Color("#725641"))
	draw_line(Vector2(x + 25, 615), Vector2(x + 135, 623), TIMBER, 7)
	for xx: float in [x + 20.0, x + 105.0]:
		draw_circle(Vector2(xx, 627), 21, Color("#423d37"))
		draw_circle(Vector2(xx, 627), 10, Color("#9c8666"))
	for k: int in range(4):
		draw_rect(Rect2(x + k * 27, 554, 24, 34), Color("#947653"))

func _draw_market_sign() -> void:
	# Roadside hanging wooden sign, deliberately graphic rather than UI.
	draw_line(Vector2(1035, 600), Vector2(1035, 425), TIMBER, 10)
	draw_line(Vector2(1035, 430), Vector2(1170, 430), TIMBER, 7)
	draw_line(Vector2(1148, 430), Vector2(1148, 458), TIMBER, 3)
	draw_rect(Rect2(1082, 458, 135, 47), Color("#51453c"))
	draw_rect(Rect2(1087, 463, 125, 37), Color("#836c50"), false, 2.0)
