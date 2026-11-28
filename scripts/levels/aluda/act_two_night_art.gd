@tool
extends Node2D
## Act II night shelter, with a dream palette for the dagger decision.
## Scenery never owns collision, combat, or the dream outcome.

@export var dream_mode: bool = false
@export var ground_y: float = 440.0
@export var show_shade: bool = false
@export var show_dagger_markers: bool = false
@export var fire_lit: bool = false

var _time: float = 0.0
var _redraw: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	_redraw += delta
	if _redraw >= 0.09:
		_redraw = 0.0
		queue_redraw()


func _draw() -> void:
	_draw_sky()
	_draw_stars()
	_draw_mountains()
	_draw_rock_shelter()
	_draw_fire()
	_draw_camp_points()
	_draw_dream_gathering()
	_draw_dream_landmarks()
	_draw_ground()


func _draw_sky() -> void:
	var top: Color = Color("#251e32") if dream_mode else Color("#101f2e")
	var horizon: Color = Color("#77545d") if dream_mode else Color("#536a75")
	for i in range(60):
		var t: float = float(i) / 59.0
		var y: float = -800.0 + t * 1260.0
		draw_rect(Rect2(-1100, y, 5100, 24.0), top.lerp(horizon, t))
	var moon: Vector2 = Vector2(1550, -30)
	draw_circle(moon, 67.0, Color("#e4bec0", 0.1) if dream_mode else Color("#dfdfcd", 0.1))
	draw_circle(moon, 37.0, Color("#e1b0b4") if dream_mode else Color("#ebeadc"))


func _draw_stars() -> void:
	for i in range(95):
		var x: float = -700.0 + float((i * 199) % 3850)
		var y: float = -650.0 + float((i * 113) % 520)
		var flicker: float = 0.34 + 0.2 * sin(_time * 1.2 + float(i))
		draw_circle(Vector2(x, y), 1.0 + float(i % 3) * 0.45, Color("#f7e9d8", flicker))


func _draw_mountains() -> void:
	var far := PackedVector2Array([
		Vector2(-1200, 500), Vector2(-1200, 110), Vector2(-870, -30),
		Vector2(-560, 90), Vector2(-170, -140), Vector2(140, 60),
		Vector2(480, -220), Vector2(770, 20), Vector2(1090, -170),
		Vector2(1450, 75), Vector2(1780, -180), Vector2(2180, 30),
		Vector2(2550, -60), Vector2(3100, 180), Vector2(3100, 500)
	])
	draw_colored_polygon(far, Color("#65546c") if dream_mode else Color("#455c70"))
	var mid := PackedVector2Array([
		Vector2(-1200, 520), Vector2(-1200, 290), Vector2(-930, 145),
		Vector2(-620, 250), Vector2(-260, 100), Vector2(120, 239),
		Vector2(430, 59), Vector2(730, 225), Vector2(1030, 90),
		Vector2(1340, 241), Vector2(1680, 100), Vector2(2000, 237),
		Vector2(2380, 160), Vector2(3100, 340), Vector2(3100, 520)
	])
	draw_colored_polygon(mid, Color("#49394f") if dream_mode else Color("#2b4653"))
	for j in range(28):
		var x: float = -700 + float(j) * 133.0
		var y: float = 253 + float((j * 17) % 50)
		draw_line(Vector2(x, y), Vector2(x + 57, y + 34), Color("#b7b0b2", 0.1), 1.6)


func _draw_rock_shelter() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(260, 445), Vector2(282, 280), Vector2(374, 236),
		Vector2(610, 211), Vector2(774, 282), Vector2(807, 445)
	]), Color("#29343c") if not dream_mode else Color("#3b3039"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(317, 446), Vector2(341, 312), Vector2(454, 297),
		Vector2(634, 305), Vector2(705, 446)
	]), Color("#111e26") if not dream_mode else Color("#211b25"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(266, 345), Vector2(282, 281), Vector2(370, 234),
		Vector2(607, 210), Vector2(768, 281), Vector2(698, 321),
		Vector2(560, 272), Vector2(402, 288)
	]), Color("#748089", 0.39))
	for j in range(12):
		var x: float = 290.0 + float(j) * 39.0
		draw_line(Vector2(x, 296.0 - float(j % 4) * 13.0), Vector2(x + 19, 351), Color("#131f2a", 0.4), 1.7)


func _draw_fire() -> void:
	var x: float = 540.0
	var glow: float = (13.0 if fire_lit or dream_mode else 3.0) + sin(_time * 5.0) * 3.0
	draw_circle(Vector2(x, 406), 83.0, Color("#db875b", 0.08) if not dream_mode else Color("#c46b80", 0.09))
	for i in range(7):
		var dx: float = float(i - 3) * 15.0
		draw_circle(Vector2(x + dx, 429), 13.0, Color("#4e5657"))
		draw_line(Vector2(x - 26, 439), Vector2(x + 24, 433), Color("#775947"), 7.0, true)
		draw_line(Vector2(x + 22, 439), Vector2(x - 21, 428), Color("#a5805d"), 6.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 15, 432), Vector2(x - 19, 407),
		Vector2(x - 4, 408 - glow), Vector2(x + 3, 410),
		Vector2(x + 17, 402 - glow * 0.42), Vector2(x + 18, 428)
	]), Color("#f4b36f", 0.9) if not dream_mode else Color("#d7a4a0", 0.85))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 7, 432), Vector2(x - 4, 409),
		Vector2(x + 2, 404 - glow * 0.55), Vector2(x + 10, 432)
	]), Color("#fff0ae", 0.83))


func _draw_camp_points() -> void:
	if dream_mode:
		return
	# Rifle leaning on the shelter rock.
	draw_line(Vector2(372, 440), Vector2(392, 372), Color("#5b4433"), 4.0)
	draw_line(Vector2(390, 378), Vector2(396, 352), Color("#9aa3a6"), 2.0)
	# Lookout stone above the road.
	draw_colored_polygon(PackedVector2Array([
		Vector2(925, 441), Vector2(935, 410), Vector2(965, 400), Vector2(992, 414), Vector2(998, 441)
	]), Color("#3c4a52"))
	# Road marker toward home.
	draw_line(Vector2(1800, 440), Vector2(1800, 392), Color("#8b8f86"), 5.0)
	draw_line(Vector2(1786, 398), Vector2(1822, 392), Color("#8b8f86"), 4.0)


func _draw_dream_gathering() -> void:
	if not dream_mode or not show_shade:
		return
	# Seated warriors around a low meal; the food is implied, never shown.
	draw_rect(Rect2(640, 425, 120, 10), Color("#4a3a40"))
	for i in range(5):
		var x: float = 600.0 + float(i) * 50.0
		draw_circle(Vector2(x, 400), 9.0, Color("#16121a", 0.8))
		draw_rect(Rect2(x - 10, 408, 20, 30), Color("#16121a", 0.8))
	# Mutsal's shade.
	var sway: float = sin(_time * 1.6) * 3.0
	draw_circle(Vector2(1080 + sway, 372), 12.0, Color("#c9b4c4", 0.55))
	draw_rect(Rect2(1068 + sway, 384, 24, 56), Color("#c9b4c4", 0.45))
	draw_line(Vector2(1092 + sway, 398), Vector2(1112 + sway, 380), Color("#e6dce4", 0.7), 2.0)


func _draw_dream_landmarks() -> void:
	if not dream_mode or not show_dagger_markers:
		return
	# Two deliberate actions will determine the dream decision.
	for position_x in [850.0, 1220.0]:
		draw_circle(Vector2(position_x, 433), 43.0, Color("#b4a9a6", 0.16))
		draw_line(Vector2(position_x - 23, 440), Vector2(position_x + 24, 440), Color("#d5b7ae", 0.61), 2.0)
		draw_line(Vector2(position_x, 391), Vector2(position_x, 440), Color("#a896a1", 0.54), 1.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1198, 401), Vector2(1221, 366), Vector2(1244, 401),
		Vector2(1234, 434), Vector2(1208, 434)
	]), Color("#ad8997", 0.43))


func _draw_ground() -> void:
	draw_rect(Rect2(-1100, ground_y, 5100, 700), Color("#1c2c31") if not dream_mode else Color("#2d2631"))
	draw_line(Vector2(-1100, ground_y), Vector2(4000, ground_y), Color("#66746f"), 2.0)
	for i in range(85):
		var x: float = -600 + float(i) * 46.0
		var h: float = 3.0 + float((i * 7) % 15)
		draw_line(Vector2(x, ground_y), Vector2(x + 6.0, ground_y - h), Color("#627269", 0.52), 1.3)
