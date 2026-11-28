@tool
extends Node2D
## Decorative Khevsureti-inspired alpine backdrop for Act 1 / Aluda preview.
## Three camera-relative mountain planes, thin drifting clouds and dawn sky.
## No collision, input, or story logic lives here.

@export var ground_y: float = 440.0
@export var clouds_move: bool = true
@export_range(0.0, 30.0, 0.5) var wind_speed: float = 6.0

const SKY_TOP := Color("#526b81")
const SKY_MID := Color("#94a9ad")
const SKY_HORIZON := Color("#ead0ad")
const FAR_ROCK := Color("#8195a2")
const FAR_LIGHT := Color("#b2bfc1")
const MID_ROCK := Color("#526c78")
const MID_LIGHT := Color("#789096")
const NEAR_ROCK := Color("#344f53")
const NEAR_LIGHT := Color("#567067")

# x-center, vertical prominence, half-width. Irregular high Caucasus ridgelines.
const FAR_PEAKS := [
	Vector3(-2650, 270, 780), Vector3(-1690, 335, 720),
	Vector3(-660, 275, 710), Vector3(270, 300, 800),
	Vector3(1220, 325, 820), Vector3(2200, 290, 750),
	Vector3(3160, 345, 840), Vector3(4170, 295, 730),
	Vector3(5190, 310, 850), Vector3(6040, 260, 770),
]
const MID_PEAKS := [
	Vector3(-2530, 185, 680), Vector3(-1510, 232, 750),
	Vector3(-590, 172, 610), Vector3(410, 225, 710),
	Vector3(1320, 168, 620), Vector3(2190, 220, 750),
	Vector3(3110, 195, 670), Vector3(3970, 236, 710),
	Vector3(4940, 176, 710), Vector3(5900, 225, 710),
]
const NEAR_PEAKS := [
	Vector3(-2550, 104, 670), Vector3(-1450, 145, 850),
	Vector3(-390, 125, 710), Vector3(560, 148, 780),
	Vector3(1490, 112, 750), Vector3(2460, 145, 760),
	Vector3(3400, 116, 790), Vector3(4300, 156, 860),
	Vector3(5270, 113, 790), Vector3(6100, 137, 690),
]

var _wind_time: float = 0.0
var _redraw_clock: float = 0.0


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _process(delta: float) -> void:
	if clouds_move:
		_wind_time += delta
	_redraw_clock += delta
	if _redraw_clock >= 0.05:
		_redraw_clock = 0.0
		queue_redraw()


func _draw() -> void:
	var camera_x := 0.0
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		camera_x = camera.global_position.x
	_draw_sky()
	_draw_sunlight(camera_x)
	_draw_clouds(camera_x)
	_draw_mountains(0, camera_x * 0.85, FAR_ROCK, FAR_LIGHT)
	_draw_mountains(1, camera_x * 0.59, MID_ROCK, MID_LIGHT)
	_draw_mountains(2, camera_x * 0.32, NEAR_ROCK, NEAR_LIGHT)
	_draw_scrub(camera_x * 0.32)


func _draw_sky() -> void:
	for i in range(76):
		var t: float = float(i) / 75.0
		var tint: Color
		if t < 0.58:
			tint = SKY_TOP.lerp(SKY_MID, t / 0.58)
		else:
			tint = SKY_MID.lerp(SKY_HORIZON, (t - 0.58) / 0.42)
		var y: float = lerpf(-1400.0, ground_y + 115.0, t)
		draw_rect(Rect2(-5400, y, 17000, 28), tint)
	for i in range(6):
		draw_rect(Rect2(-5400, 185.0 + float(i) * 28.0, 17000, 32), Color("#e4d4ba", 0.025 + float(i) * 0.009))


func _draw_sunlight(camera_x: float) -> void:
	var center := Vector2(120.0 + camera_x * 0.89, 118.0)
	for i in range(8, 0, -1):
		var radius: float = 34.0 + float(i) * 27.0
		_oval(center, Vector2(radius, radius), Color("#f6daaa", 0.018))
	_oval(center, Vector2(33.0, 33.0), Color("#fff1d2", 0.62))


func _draw_clouds(camera_x: float) -> void:
	for i in range(13):
		var drift: float = _wind_time * wind_speed * (0.7 + float(i % 4) * 0.12)
		var x: float = -2000.0 + float(i) * 500.0 + drift + camera_x * 0.91
		var y: float = 95.0 + float((i * 47) % 140)
		var width: float = 110.0 + float((i * 53) % 105)
		_draw_cloud(Vector2(x, y), width)


func _draw_cloud(center: Vector2, width: float) -> void:
	_oval(center + Vector2(0, 9), Vector2(width * 1.13, 16), Color("#576e7c", 0.16))
	_oval(center + Vector2(0, -2), Vector2(width, 17), Color("#e6e3d7", 0.36))
	_oval(center + Vector2(-width * 0.35, -12), Vector2(width * 0.46, 25), Color("#f1e9d8", 0.39))
	_oval(center + Vector2(width * 0.16, -19), Vector2(width * 0.52, 29), Color("#f6ead7", 0.40))
	_oval(center + Vector2(width * 0.48, -5), Vector2(width * 0.40, 18), Color("#f0e7d8", 0.32))


func _oval(center: Vector2, radius: Vector2, tint: Color) -> void:
	var polygon := PackedVector2Array()
	for j in range(25):
		var angle: float = TAU * float(j) / 24.0
		polygon.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(polygon, tint)


func _peak_list(band: int) -> Array:
	match band:
		0:
			return FAR_PEAKS
		1:
			return MID_PEAKS
		_:
			return NEAR_PEAKS


func _ridge_y(x: float, band: int) -> float:
	var base: float = ground_y - 54.0 + float(band) * 53.0
	var height: float = 0.0
	for peak in _peak_list(band):
		var reach: float = maxf(0.0, 1.0 - absf(x - peak.x) / peak.z)
		height = maxf(height, peak.y * pow(reach, 0.86))
	var rough: float = float(band) * 1.37
	return base - height + 10.0 * sin(x * 0.024 + rough) + 4.5 * sin(x * 0.085 - rough)


func _draw_mountains(band: int, offset_x: float, rock: Color, light: Color) -> void:
	var polygon := PackedVector2Array()
	polygon.append(Vector2(-3000.0 + offset_x, ground_y + 340.0))
	for i in range(421):
		var x: float = -3000.0 + float(i) * 23.0
		polygon.append(Vector2(x + offset_x, _ridge_y(x, band)))
	polygon.append(Vector2(6660.0 + offset_x, ground_y + 340.0))
	draw_colored_polygon(polygon, rock)
	var facet_count: int = 71 if band < 2 else 83
	for i in range(facet_count):
		var x: float = -2900.0 + float(i) * (128.0 if band < 2 else 112.0)
		var y: float = _ridge_y(x, band)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x + offset_x, y + 7.0),
			Vector2(x + offset_x + side * 53.0, _ridge_y(x + side * 53.0, band) + 16.0),
			Vector2(x + offset_x + side * 25.0, y + 73.0 + float(i % 3) * 13.0),
		]), Color(light, 0.27 if band == 0 else 0.24))
		if i % 3 == 0:
			draw_line(Vector2(x + offset_x, y + 12.0), Vector2(x + offset_x + 21.0, y + 96.0), Color("#243b48", 0.17), 1.5)
	if band == 0:
		_draw_snow(offset_x)
	elif band == 1:
		_draw_scree(offset_x)


func _draw_snow(offset_x: float) -> void:
	for peak in FAR_PEAKS:
		if peak.y < 290.0:
			continue
		var x: float = peak.x
		var y: float = _ridge_y(x, 0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 61.0 + offset_x, _ridge_y(x - 61.0, 0) + 9.0),
			Vector2(x + offset_x, y + 4.0),
			Vector2(x + 37.0 + offset_x, _ridge_y(x + 37.0, 0) + 10.0),
			Vector2(x + 26.0 + offset_x, y + 61.0),
			Vector2(x - 5.0 + offset_x, y + 42.0),
			Vector2(x - 32.0 + offset_x, y + 73.0),
		]), Color("#dfe5df", 0.79))


func _draw_scree(offset_x: float) -> void:
	for i in range(140):
		var x: float = -2900.0 + float(i) * 69.0
		var y: float = _ridge_y(x, 1) + 33.0 + float((i * 19) % 80)
		draw_line(Vector2(x + offset_x, y), Vector2(x + 7.0 + offset_x, y - 2.0), Color("#adaba0", 0.25), 1.3)


func _draw_scrub(offset_x: float) -> void:
	for i in range(91):
		var x: float = -2700.0 + float(i) * 99.0
		var y: float = _ridge_y(x, 2) + 6.0
		var h: float = 8.0 + float((i * 37) % 18)
		if i % 5 == 0:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x + offset_x, y - h),
				Vector2(x - h * 0.45 + offset_x, y + 2.0),
				Vector2(x + h * 0.45 + offset_x, y + 2.0),
			]), Color("#203a3b", 0.62))
		else:
			draw_line(Vector2(x + offset_x, y), Vector2(x + offset_x + 5.0, y - h * 0.45), Color("#8a9680", 0.46), 1.5)
