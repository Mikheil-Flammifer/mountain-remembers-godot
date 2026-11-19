extends Node2D

## Mtskheta terraces: standalone warm-green scenery.
## Visual only; platforms, collisions, exits and thorns remain in terraces.tscn.

const LEVEL_WIDTH: float = 5100.0
const GROUND_Y: float = 650.0

const SKY_TOP := Color("#eee0c2")
const SKY_BOTTOM := Color("#dcc7a6")
const FAR_MOUNTAIN := Color("#aab094")
const MID_MOUNTAIN := Color("#8b9978")
const NEAR_MOUNTAIN := Color("#687f60")
const STONE_GROUND := Color("#75654b")
const STONE_TOP := Color("#b6a17a")
const STONE_LINE := Color("#5e5745")
const MOSS := Color("#78875b")
const JVARI_DARK := Color("#46483d")
const JVARI_LIGHT := Color("#696c55")

func _ready() -> void:
	z_index = -20
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_mountain(_far_ridge(), FAR_MOUNTAIN)
	_draw_mountain(_mid_ridge(), MID_MOUNTAIN)
	_draw_mountain(_near_ridge(), NEAR_MOUNTAIN)
	_draw_jvari_church()
	_draw_ground()

func _draw_sky() -> void:
	draw_rect(Rect2(0, -500, LEVEL_WIDTH, 1300), SKY_BOTTOM)
	draw_rect(Rect2(0, -500, LEVEL_WIDTH, 180), SKY_TOP)
	draw_circle(Vector2(4070, -60), 160, Color("#f4e4b9", 0.22))

## Interpolate between the original ridge control points with Catmull-Rom
## curves. This removes the angular zigzags without changing their silhouette.
func _draw_mountain(ridge: PackedVector2Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	for i in range(ridge.size() - 1):
		var p0: Vector2 = ridge[maxi(0, i - 1)]
		var p1: Vector2 = ridge[i]
		var p2: Vector2 = ridge[i + 1]
		var p3: Vector2 = ridge[mini(ridge.size() - 1, i + 2)]
		for step in range(8):
			var t: float = float(step) / 8.0
			var t2: float = t * t
			var t3: float = t2 * t
			var y: float = 0.5 * ((2.0 * p1.y) + (-p0.y + p2.y) * t + (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 + (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)
			polygon.append(Vector2(lerpf(p1.x, p2.x, t), y))
	polygon.append(ridge[ridge.size() - 1])
	polygon.append(Vector2(LEVEL_WIDTH, GROUND_Y))
	polygon.append(Vector2(0, GROUND_Y))
	draw_colored_polygon(polygon, color)

func _far_ridge() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0,430), Vector2(180,405), Vector2(350,370),
		Vector2(520,382), Vector2(710,342), Vector2(910,355),
		Vector2(1120,315), Vector2(1320,338), Vector2(1490,300),
		Vector2(1710,332), Vector2(1910,392), Vector2(2080,365),
		Vector2(2270,322), Vector2(2480,345), Vector2(2670,305),
		Vector2(2860,320), Vector2(3050,290), Vector2(3250,315),
		Vector2(3450,280), Vector2(3650,325), Vector2(3830,375),
		Vector2(4010,345), Vector2(4190,310), Vector2(4370,328),
		Vector2(4560,292), Vector2(4740,315), Vector2(4910,288),
		Vector2(5100,325)
	])

func _mid_ridge() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0,520), Vector2(120,485), Vector2(260,438),
		Vector2(420,452), Vector2(590,408), Vector2(760,432),
		Vector2(930,372), Vector2(1100,395), Vector2(1270,356),
		Vector2(1450,388), Vector2(1630,350), Vector2(1810,420),
		Vector2(1980,470), Vector2(2150,438), Vector2(2330,395),
		Vector2(2510,425), Vector2(2680,380), Vector2(2860,405),
		Vector2(3040,360), Vector2(3230,390), Vector2(3420,352),
		Vector2(3600,430), Vector2(3780,485), Vector2(3960,448),
		Vector2(4140,398), Vector2(4320,420), Vector2(4500,382),
		Vector2(4680,408), Vector2(4860,370), Vector2(5100,440)
	])

func _near_ridge() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0,590), Vector2(130,565), Vector2(260,532),
		Vector2(390,545), Vector2(540,508), Vector2(690,525),
		Vector2(840,482), Vector2(990,500), Vector2(1160,455),
		Vector2(1320,482), Vector2(1490,448), Vector2(1670,505),
		Vector2(1840,552), Vector2(1990,535), Vector2(2160,492),
		Vector2(2320,512), Vector2(2490,472), Vector2(2670,500),
		Vector2(2850,458), Vector2(3020,485), Vector2(3190,445),
		Vector2(3360,510), Vector2(3530,560), Vector2(3690,540),
		Vector2(3860,500), Vector2(4020,520), Vector2(4180,480),
		Vector2(4350,510), Vector2(4520,468), Vector2(4690,492),
		Vector2(4860,460), Vector2(5100,540)
	])

func _draw_jvari_church() -> void:
	# A small, recognizable Jvari-inspired cross-domed church on its ridge.
	var x: float = 980.0
	var y: float = 356.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 72,y + 28), Vector2(x - 15,y + 8),
		Vector2(x + 48,y + 18), Vector2(x + 86,y + 34),
		Vector2(x - 72,y + 34)
	]), Color("#647157"))
	draw_rect(Rect2(x, y - 8, 34, 28), JVARI_DARK)
	draw_rect(Rect2(x - 10, y + 2, 12, 14), JVARI_DARK)
	draw_rect(Rect2(x + 32, y + 2, 10, 14), JVARI_DARK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 4,y - 8), Vector2(x + 17,y - 22),
		Vector2(x + 38,y - 8)
	]), JVARI_LIGHT)
	draw_rect(Rect2(x + 11, y - 20, 12, 12), JVARI_DARK)
	draw_line(Vector2(x + 17,y - 28), Vector2(x + 17,y - 19), JVARI_LIGHT, 2.0)
	draw_line(Vector2(x + 12,y - 24), Vector2(x + 22,y - 24), JVARI_LIGHT, 2.0)

func _draw_ground() -> void:
	draw_rect(Rect2(0, GROUND_Y, LEVEL_WIDTH, 170), STONE_GROUND)
	draw_rect(Rect2(0, GROUND_Y, LEVEL_WIDTH, 7), MOSS)
	draw_line(Vector2(0, GROUND_Y + 7), Vector2(LEVEL_WIDTH, GROUND_Y + 7), STONE_TOP, 2.0)
	for row in range(3):
		var y: float = 687.0 + float(row) * 39.0
		draw_line(Vector2(0,y), Vector2(LEVEL_WIDTH,y), STONE_LINE, 2.0)
		var offset: float = 50.0 if row % 2 == 0 else 0.0
		for i in range(56):
			var x: float = float(i) * 94.0 + offset
			if x < LEVEL_WIDTH:
				draw_line(Vector2(x,y), Vector2(x,y + 35), STONE_LINE, 1.4)
	for i in range(95):
		var x: float = 23.0 + float(i) * 54.0
		var h: float = 5.0 + float(i % 4) * 2.0
		draw_line(Vector2(x,GROUND_Y), Vector2(x - 4,GROUND_Y - h), MOSS, 1.5)
		draw_line(Vector2(x,GROUND_Y), Vector2(x + 4,GROUND_Y - h * 0.7), Color("#9a9c69"), 1.0)
