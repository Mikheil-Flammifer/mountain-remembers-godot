@tool
extends Node2D
## One independently editable, collision-free Act 1 landscape section.
## Coordinates are LOCAL to the area scene; the area scene sets world position.
## The player, floor, clues, and encounters are owned by act_one_tracking.gd.

@export_range(0, 3, 1) var region_id: int = 0
@export_range(250.0, 2000.0, 10.0) var region_width: float = 700.0
@export var ground_y: float = 440.0
@export var animate_wind: bool = true

const SLATE_DARK := Color("#304547")
const SLATE := Color("#5b6b67")
const SLATE_LIT := Color("#929c8b")
const EARTH := Color("#566657")
const OCHRE := Color("#ac9f7c")
const WOOD := Color("#514a40")
const HERB := Color("#8c9b77")

var _time: float = 0.0
var _clock: float = 0.0


func _process(delta: float) -> void:
	if not animate_wind:
		return
	_time += delta
	_clock += delta
	if _clock >= 0.085:
		_clock = 0.0
		queue_redraw()


func _draw() -> void:
	match region_id:
		0:
			_shepherds_fold()
		1:
			_wind_pasture()
		2:
			_sanata_ford()
		3:
			_arkhoti_crags()


func _poly(points: Array[Vector2], tint: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), tint)


func _stone(x: float, y: float, w: float, h: float, tint: Color = SLATE) -> void:
	_poly([
		Vector2(x - w * 0.54, y),
		Vector2(x - w * 0.49, y - h * 0.58),
		Vector2(x - w * 0.16, y - h),
		Vector2(x + w * 0.36, y - h * 0.78),
		Vector2(x + w * 0.52, y - h * 0.3),
		Vector2(x + w * 0.57, y)
	], tint)
	_poly([
		Vector2(x - w * 0.48, y - h * 0.59),
		Vector2(x - w * 0.16, y - h),
		Vector2(x + w * 0.04, y - h * 0.71),
		Vector2(x - w * 0.03, y)
	], Color(SLATE_LIT, 0.2))
	draw_line(Vector2(x + w * 0.04, y - h * 0.7), Vector2(x + w * 0.16, y - h * 0.18), Color(SLATE_DARK, 0.58), 1.2)


func _reed(x: float, y: float, height: float, phase: float = 0.0) -> void:
	var swing: float = sin(_time * 1.3 + phase) * 3.0 if animate_wind else 0.0
	draw_line(Vector2(x, y), Vector2(x - 2 + swing, y - height), Color("#9ba786", 0.79), 1.4)
	draw_line(Vector2(x, y), Vector2(x + 5 + swing, y - height * 0.78), Color("#b9ae89", 0.62), 1.1)
	draw_line(Vector2(x, y), Vector2(x - 7 + swing, y - height * 0.52), Color("#5c7564", 0.63), 1.5)


func _slate_masonry(origin: Vector2, columns: int, rows: int, size: Vector2) -> void:
	for row in range(rows):
		for col in range(columns):
			var jitter: float = float((row * 11 + col * 7) % 4)
			var x: float = origin.x + float(col) * size.x + (size.x * 0.4 if row % 2 else 0.0)
			var y: float = origin.y + float(row) * size.y
			draw_rect(Rect2(x + 1, y + 1, size.x - 2, size.y - 2 - jitter), Color("#626f68" if (col + row) % 3 else "#485854"))
			draw_line(Vector2(x + 2, y + 2), Vector2(x + size.x - 3, y + 2), Color("#b8b4a0", 0.21), 1.0)


func _path(from_x: float, to_x: float, lift: float = 0.0) -> void:
	# A quiet path guiding the eye; gameplay terrain remains a flat physical floor.
	_poly([
		Vector2(from_x, ground_y - 2.0),
		Vector2(from_x + 36.0, ground_y - 6.0 - lift),
		Vector2(to_x - 32.0, ground_y - 7.0 - lift * 0.5),
		Vector2(to_x, ground_y - 2.0),
		Vector2(to_x, ground_y + 4.0),
		Vector2(from_x, ground_y + 4.0)
	], Color("#bcaf8e", 0.19))
	for i in range(15):
		var x: float = lerpf(from_x + 23.0, to_x - 20.0, float(i) / 14.0)
		draw_line(Vector2(x, ground_y - 3.0), Vector2(x + 6 + float(i % 4) * 3.0, ground_y - 4.0), Color("#d1c3a1", 0.2), 1.0)


func _shepherds_fold() -> void:
	# Behind the original sheepfold clues, an abandoned shepherd's shelter.
	_poly([
		Vector2(0, ground_y), Vector2(0, 372), Vector2(74, 347),
		Vector2(162, 366), Vector2(245, 332), Vector2(337, 368),
		Vector2(423, 351), Vector2(region_width, 384),
		Vector2(region_width, ground_y)
	], Color("#526b62", 0.47))
	for i in range(8):
		var x: float = float(i) * (region_width / 7.0)
		draw_line(Vector2(x, 376 + float(i % 3) * 8), Vector2(x + 36, 395 + float(i % 4) * 4), Color("#a2ab93", 0.2), 1.4)

	# Shallow slate hut: the door is atmospheric, not an interactable entry.
	var hut_x: float = 105.0
	_poly([
		Vector2(hut_x - 70, 427), Vector2(hut_x - 66, 326),
		Vector2(hut_x - 31, 301), Vector2(hut_x + 39, 301),
		Vector2(hut_x + 76, 329), Vector2(hut_x + 76, 428)
	], Color("#394e4c"))
	_poly([
		Vector2(hut_x - 79, 330), Vector2(hut_x - 34, 285),
		Vector2(hut_x + 43, 285), Vector2(hut_x + 87, 330),
		Vector2(hut_x + 39, 314), Vector2(hut_x - 31, 314)
	], Color("#263d42"))
	_poly([
		Vector2(hut_x - 67, 328), Vector2(hut_x - 31, 302),
		Vector2(hut_x - 31, 420), Vector2(hut_x - 66, 427)
	], Color("#829083", 0.26))
	_slate_masonry(Vector2(hut_x - 62, 327), 8, 7, Vector2(17, 13))
	draw_rect(Rect2(hut_x - 11, 362, 25, 66), Color("#1a3034"))
	draw_line(Vector2(hut_x - 8, 365), Vector2(hut_x - 8, 425), Color("#9a9784", 0.3), 2)
	draw_rect(Rect2(hut_x + 35, 339, 11, 19), Color("#1a3237"))
	_stone(15, 439, 82, 33, Color("#465954"))
	_stone(208, 442, 63, 27, Color("#53675e"))
	for i in range(18):
		_reed(8.0 + float(i) * 15, ground_y, 10.0 + float((i * 3) % 10), float(i))
	_path(255, region_width)


func _wind_pasture() -> void:
	# Broad stepped alpine slopes, exposed to a constant mountain wind.
	_poly([
		Vector2(0, ground_y), Vector2(0, 332), Vector2(48, 346),
		Vector2(117, 309), Vector2(191, 334), Vector2(273, 301),
		Vector2(357, 339), Vector2(441, 317),
		Vector2(region_width, 371), Vector2(region_width, ground_y)
	], Color("#728579", 0.27))
	for i in range(7):
		var x: float = float(i) * region_width / 6.0
		draw_line(Vector2(x, 359 + float(i % 3) * 8), Vector2(x + 76, 350 + float((i * 3) % 19)), Color("#b5ba9b", 0.25), 1.7)
	# Scattered shale terraces and a small windbent mountain juniper.
	for i in range(16):
		var x: float = 20.0 + float(i) * (region_width - 40.0) / 15.0
		var y: float = 393.0 + float((i * 7) % 26)
		draw_line(Vector2(x, y), Vector2(x + 31.0 + float(i % 3) * 11.0, y - 4.0), Color("#a8ad95", 0.30), 2)
	_stone(region_width * 0.62, 438, 58, 30, Color("#56695f"))
	_stone(region_width * 0.78, 442, 39, 23, Color("#69786c"))
	for i in range(43):
		var x: float = 12.0 + float(i) * (region_width - 24.0) / 42.0
		_reed(x, ground_y - float(i % 4), 9.0 + float((i * 13) % 17), float(i) * 0.37)
	_path(0, region_width)
	# Slanted stone way marker; its height is visual only.
	_poly([
		Vector2(region_width - 82, 440), Vector2(region_width - 76, 375),
		Vector2(region_width - 57, 362), Vector2(region_width - 51, 440)
	], Color("#475d59"))
	draw_line(Vector2(region_width - 72, 386), Vector2(region_width - 62, 387), Color("#b9b499", 0.46), 2.0)


func _sanata_ford() -> void:
	# A narrowing river gorge with an herb-keeper's lean-to.
	_poly([
		Vector2(0, ground_y), Vector2(0, 365), Vector2(90, 386),
		Vector2(151, 339), Vector2(210, 361), Vector2(323, 347),
		Vector2(429, 371), Vector2(516, 350),
		Vector2(region_width, 399), Vector2(region_width, ground_y)
	], Color("#586f70", 0.43))
	# Backdrop bank and narrow distant waterfall.
	_poly([
		Vector2(386, 359), Vector2(409, 337), Vector2(429, 362),
		Vector2(423, 420), Vector2(382, 419)
	], Color("#344d54", 0.63))
	draw_line(Vector2(410, 344), Vector2(409, 417), Color("#b3c9c0", 0.49), 6)
	draw_line(Vector2(418, 351), Vector2(414, 414), Color("#6e9a9c", 0.63), 3)
	for i in range(12):
		var x: float = 360.0 + float(i) * 17.0
		draw_line(Vector2(x, 417 + float(i % 3)), Vector2(x + 13, 420 + float(i % 4)), Color("#bfd5cc", 0.23), 1.2)

	# Sanata's herb-shelter stays BEHIND the playable character at x=1400.
	var shelter_x: float = 111.0
	draw_line(Vector2(shelter_x - 53, 433), Vector2(shelter_x - 49, 330), Color("#4a4740"), 5)
	draw_line(Vector2(shelter_x + 68, 433), Vector2(shelter_x + 65, 335), Color("#4a4740"), 5)
	_poly([
		Vector2(shelter_x - 70, 339), Vector2(shelter_x - 41, 319),
		Vector2(shelter_x + 79, 327), Vector2(shelter_x + 91, 341),
		Vector2(shelter_x + 54, 338)
	], Color("#514e42"))
	draw_line(Vector2(shelter_x - 55, 345), Vector2(shelter_x + 70, 342), Color("#a99b79", 0.53), 2)
	for i in range(9):
		var x: float = shelter_x - 45.0 + float(i) * 11
		var herb_y: float = 351.0 + float(i % 3) * 5
		draw_line(Vector2(x, 345), Vector2(x + 2, herb_y + 25), Color("#a7aa7d", 0.73), 1.5)
		draw_circle(Vector2(x + 2, herb_y + 25), 3.0, Color("#768969", 0.68))
	_stone(shelter_x + 47, 438, 40, 23, Color("#617268"))
	for i in range(35):
		var x: float = float(i) * (region_width / 35.0)
		if x > 50 and x < 230:
			continue
		_reed(x, ground_y, 13.0 + float(i % 7) * 2.0, float(i) * 0.8)
	# Retain the original ford's visually continuous, safe walking surface.
	_path(250, region_width)


func _arkhoti_crags() -> void:
	# Dramatic, fractured, wind-scoured slate at the far end of the pursuit.
	var peaks := [
		Vector3(30, 188, 92), Vector3(158, 260, 126),
		Vector3(324, 215, 113), Vector3(483, 298, 151),
		Vector3(671, 235, 108), Vector3(834, 318, 159),
		Vector3(1054, 251, 144), Vector3(1261, 300, 131)
	]
	for i in range(peaks.size()):
		var peak: Vector3 = peaks[i]
		_poly([
			Vector2(peak.x - peak.z * 0.62, ground_y + 30),
			Vector2(peak.x - peak.z * 0.47, ground_y - peak.y * 0.48),
			Vector2(peak.x - peak.z * 0.10, ground_y - peak.y),
			Vector2(peak.x + peak.z * 0.20, ground_y - peak.y * 0.74),
			Vector2(peak.x + peak.z * 0.54, ground_y - peak.y * 0.32),
			Vector2(peak.x + peak.z * 0.65, ground_y + 30)
		], Color("#334c4e" if i % 2 else "#405758", 0.83))
		draw_line(
			Vector2(peak.x - peak.z * 0.11, ground_y - peak.y + 16),
			Vector2(peak.x + peak.z * 0.21, ground_y - peak.y * 0.32),
			Color("#b3b3a2", 0.24), 2.1
		)
		draw_line(
			Vector2(peak.x + peak.z * 0.21, ground_y - peak.y * 0.32),
			Vector2(peak.x + peak.z * 0.09, ground_y + 24),
			Color("#1d343a", 0.45), 1.5
		)
	# Windblown scree fans connect the cliff bases and mark the dangerous pass.
	for i in range(43):
		var x: float = 17.0 + float(i) * (region_width - 40.0) / 42.0
		var y: float = 404.0 + float((i * 13) % 30)
		draw_line(Vector2(x, y), Vector2(x + 10 + float(i % 4) * 2.0, y - 1.0), Color("#a8ae9c", 0.25), 1.3)
		if i % 3 == 0:
			_stone(x, ground_y + 1.0, 18 + float(i % 5) * 6.0, 10.0 + float(i % 7) * 2.0, Color("#586b65"))
	for i in range(19):
		var x: float = 24 + float(i) * 65.0
		draw_line(Vector2(x, 255 + float(i % 4) * 18), Vector2(x + 54, 250 + float(i % 4) * 18), Color("#d4d3bc", 0.08), 1.8)
	_path(0, region_width)
