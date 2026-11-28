@tool
extends Node2D
## Decorative Act 1 landmarks along Aluda's trail toward the Arkhoti crags.
## Everything in this script is painted with CanvasItem draw calls: no collision,
## damage, audio, or quest state. Positions match act_one_tracking.gd clues.

@export var ground_y: float = 440.0
@export var animate_birds: bool = true

const SHALE := Color("#39494a")
const SHALE_LIT := Color("#78847a")
const SHALE_SHADE := Color("#293b3e")
const MOSS := Color("#6c8165")
const OCHRE := Color("#c0a77d")
const WOOD := Color("#574f42")
const WOOD_LIT := Color("#8d806a")
const WATER := Color("#466874")

var _time: float = 0.0
var _draw_clock: float = 0.0


func _process(delta: float) -> void:
	if not animate_birds:
		return
	_time += delta
	_draw_clock += delta
	if _draw_clock > 0.08:
		_draw_clock = 0.0
		queue_redraw()


func _draw() -> void:
	_draw_distant_watchtower()
	_draw_grassy_banks()
	_draw_sheepfold()
	_draw_broken_fence()
	_draw_hoofprints()
	_draw_bent_grass()
	_draw_ford()
	_draw_trail_cairns()
	_draw_birds()
	_draw_crags()
	_draw_cover_rock()


func _stone(x: float, y: float, width: float, height: float, tint: Color = SHALE) -> void:
	var silhouette := PackedVector2Array([
		Vector2(x - width * 0.55, y + 3.0),
		Vector2(x - width * 0.49, y - height * 0.54),
		Vector2(x - width * 0.18, y - height),
		Vector2(x + width * 0.27, y - height * 0.88),
		Vector2(x + width * 0.52, y - height * 0.42),
		Vector2(x + width * 0.59, y + 3.0),
	])
	draw_colored_polygon(silhouette, tint)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - width * 0.49, y - height * 0.54),
		Vector2(x - width * 0.18, y - height),
		Vector2(x + width * 0.09, y - height * 0.73),
		Vector2(x - width * 0.06, y + 1.0),
		Vector2(x - width * 0.55, y + 3.0),
	]), Color(SHALE_LIT, 0.32))
	draw_line(Vector2(x + width * 0.1, y - height * 0.71), Vector2(x + width * 0.29, y - height * 0.12), Color(SHALE_SHADE, 0.45), 1.3)


func _ellipse(center: Vector2, radius: Vector2, tint: Color) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var angle: float = float(i) * TAU / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, tint)


func _grass(x: float, y: float, height: float, lean: float = 0.0) -> void:
	var tint := Color("#9ba37d", 0.72)
	draw_line(Vector2(x, y), Vector2(x + lean - 3.0, y - height * 0.78), tint, 1.1)
	draw_line(Vector2(x, y), Vector2(x + lean + 1.0, y - height), Color("#c6b78b", 0.68), 1.2)
	draw_line(Vector2(x, y), Vector2(x + lean + 4.0, y - height * 0.56), Color("#657b61", 0.81), 1.4)


func _draw_grassy_banks() -> void:
	# Sparse hardy grass; intentional clear space around investigation markers.
	for i in range(126):
		var x: float = -140.0 + float(i) * 28.0 + float((i * 11) % 12)
		var h: float = 5.0 + float((i * 17) % 10)
		if x > 1270.0 and x < 1810.0:
			continue
		_grass(x, ground_y, h, sin(float(i) * 1.4) * 3.0)
	for i in range(48):
		var x: float = 510.0 + float(i) * 51.0
		if x > 1280.0 and x < 1830.0:
			continue
		_ellipse(Vector2(x, ground_y + 2.0), Vector2(7.0 + float(i % 4) * 3.0, 2.0), Color(MOSS, 0.3))


func _draw_distant_watchtower() -> void:
	# A tiny distant Khevsur stone ruin: a landscape detail, not an enterable building.
	var x: float = 1970.0
	var bottom: float = 339.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 80, bottom + 23), Vector2(x - 49, bottom - 8),
		Vector2(x + 35, bottom - 2), Vector2(x + 86, bottom + 23),
	]), Color("#52665c"))
	draw_rect(Rect2(x - 17.0, bottom - 67.0, 34.0, 73.0), Color("#576666"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 19, bottom - 67),
		Vector2(x - 15, bottom - 80),
		Vector2(x + 15, bottom - 80),
		Vector2(x + 19, bottom - 67),
	]), Color("#374b4d"))
	draw_rect(Rect2(x - 4, bottom - 45, 7, 16), Color("#273e45"))
	draw_rect(Rect2(x - 4, bottom - 14, 8, 15), Color("#293b3e"))
	for row in range(5):
		var y: float = bottom - 61.0 + float(row) * 12.0
		draw_line(Vector2(x - 15, y), Vector2(x + 14, y), Color("#a5aa97", 0.30), 1.0)
		draw_line(Vector2(x - 5 + float((row * 7) % 13), y), Vector2(x - 5 + float((row * 7) % 13), y + 11), Color("#273e40", 0.37), 1.0)


func _dry_wall(x: float, top: float, segments: int, courses: int) -> void:
	# Broken, uneven dry-laid slate courses characteristic of the highlands.
	for row in range(courses):
		for col in range(segments):
			var off: float = 8.0 if row % 2 else 0.0
			var bx: float = x + float(col) * 17.0 + off
			var by: float = top + float(row) * 13.0
			var h: float = 10.0 + float((row * 3 + col * 5) % 4)
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx + 1.0, by + 2.0),
				Vector2(bx + 16.0, by + 1.0),
				Vector2(bx + 16.0, by + h),
				Vector2(bx + 1.0, by + h + 1.0),
			]), Color("#606962" if (row + col) % 2 == 0 else "#45524f"))
			draw_line(Vector2(bx + 2, by + 3), Vector2(bx + 13, by + 2), Color("#a4a58d", 0.4), 1.0)


func _draw_sheepfold() -> void:
	# Sheepfold opening at x~430; the area is visual only (not a physical gate).
	_draw_dry_base()
	_dry_wall(244.0, 388.0, 8, 4)
	_dry_wall(477.0, 395.0, 9, 3)
	for x in [239.0, 385.0, 468.0, 634.0]:
		draw_rect(Rect2(x, 361.0, 5.0, 79.0), WOOD)
		draw_line(Vector2(x + 2, 363), Vector2(x + 2, 438), WOOD_LIT, 1.0)
	draw_line(Vector2(386, 385), Vector2(437, 402), WOOD, 4.0)
	draw_line(Vector2(388, 404), Vector2(434, 420), WOOD_LIT, 3.0)
	# Hay and a shepherd's abandoned rope.
	for i in range(16):
		var x: float = 294.0 + float(i) * 3.8
		draw_line(Vector2(x, 389), Vector2(x + float((i * 7) % 9) - 4, 377.0 - float(i % 4) * 3), Color("#bba57b", 0.7), 1.4)
	draw_arc(Vector2(561.0, 438.0), 13.0, PI * 0.16, PI * 1.8, 18, Color("#a79a79"), 2.0)
	for i in range(8):
		_stone(245.0 + float(i) * 55.0, 440.0, 14.0 + float(i % 3) * 4.0, 8.0, Color("#657269"))


func _draw_dry_base() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(227, ground_y), Vector2(251, 429), Vector2(332, 430),
		Vector2(378, 434), Vector2(460, 434), Vector2(514, 427),
		Vector2(633, 434), Vector2(654, ground_y),
	]), Color("#7e806b", 0.62))


func _draw_broken_fence() -> void:
	for x in [596.0, 629.0, 661.0]:
		draw_line(Vector2(x, 437), Vector2(x - 2.0, 398.0 + float(int(x) % 4) * 3), WOOD, 4.0)
	draw_line(Vector2(593, 413), Vector2(640, 415), Color(WOOD_LIT, 0.72), 3.0)
	draw_line(Vector2(640, 415), Vector2(669, 442), WOOD, 2.5)
	_stone(664, 440, 30, 13, Color("#566158"))


func _draw_hoofprints() -> void:
	for i in range(8):
		var x: float = 691.0 + float(i) * 19.0
		var y: float = ground_y - 5.0 + float((i * 7) % 5)
		_ellipse(Vector2(x, y), Vector2(5.7, 2.3), Color("#283c37", 0.68))
		_ellipse(Vector2(x + 7.0, y + (3.0 if i % 2 else -3.0)), Vector2(4.0, 1.9), Color("#283c37", 0.6))
		if i % 2 == 0:
			draw_line(Vector2(x - 7, y + 4), Vector2(x + 4, y + 5), Color("#9c8e73", 0.35), 1.0)
	for i in range(13):
		_grass(689.0 + float(i) * 14.0, 439, 6.0, 4.0)


func _draw_bent_grass() -> void:
	_ellipse(Vector2(1054, 440), Vector2(82, 8), Color("#887e61", 0.27))
	for i in range(31):
		var x: float = 965.0 + float(i) * 6.0
		_grass(x, ground_y + float((i * 3) % 3), 11.0 + float((i * 7) % 12), 8.0 + float((i * 5) % 7))
	for i in range(5):
		draw_line(Vector2(1001 + i * 24, 434), Vector2(1031 + i * 24, 440), Color("#4b5947", 0.45), 1.6)


func _draw_ford() -> void:
	# Shallow wet ford. It does not introduce a platforming gap or a hazard.
	draw_colored_polygon(PackedVector2Array([
		Vector2(1260, 438), Vector2(1318, 426), Vector2(1455, 422),
		Vector2(1625, 427), Vector2(1782, 438), Vector2(1823, 450),
		Vector2(1260, 450),
	]), Color("#6b796b", 0.83))
	_ellipse(Vector2(1540, 439), Vector2(252, 12.0), Color(WATER, 0.81))
	for i in range(28):
		var x: float = 1309.0 + float(i) * 16.5
		var y: float = 431.0 + float((i * 13) % 8)
		draw_line(Vector2(x, y), Vector2(x + 8.0 + float(i % 5) * 2.0, y - 1.0), Color("#c7d6c2", 0.20 + float(i % 3) * 0.10), 1.2)
	for i in range(12):
		var x: float = 1282.0 + float(i) * 47.0
		_stone(x, 442.0, 18.0 + float((i * 3) % 12), 9.0 + float(i % 6), Color("#576a6a"))
	for i in range(24):
		var x: float = 1288.0 + float(i) * 22.0
		if i % 6 == 0:
			_grass(x, 427, 17.0, -3.0)
			_grass(x + 4.0, 427, 9.0, 3.0)
	# Footprints taper into the far bank.
	for i in range(5):
		var x: float = 1664.0 + float(i) * 17.0
		_ellipse(Vector2(x, 429.0 + float(i % 2) * 3.0), Vector2(5.0, 2.0), Color("#304c4b", 0.64))


func _draw_trail_cairns() -> void:
	for x in [1180.0, 1876.0, 2204.0]:
		_stone(x, 440, 38, 22, Color("#465952"))
		_stone(x - 4.0, 419, 23, 18, Color("#65736a"))
		_stone(x + 2.0, 402, 13, 12, Color("#7f887b"))
		draw_line(Vector2(x - 9, 416), Vector2(x + 2, 416), Color("#b7aa87", 0.44), 1.0)


func _draw_birds() -> void:
	for i in range(6):
		var drift: float = sin(_time * 0.24 + float(i) * 1.7) * (11.0 + float(i) * 5.0) if animate_birds else 0.0
		var x: float = 2011.0 + float(i) * 28.0 + drift
		var y: float = 206.0 + float((i * 13) % 48) + sin(_time * 0.8 + float(i)) * 4.0
		var wing: float = 6.0 + float(i % 3) * 2.0
		var flap: float = sin(_time * 2.0 + float(i) * 0.63) * 3.0 if animate_birds else 0.0
		draw_line(Vector2(x - wing, y - 3.0 + flap), Vector2(x, y), Color("#35464b", 0.72), 1.5)
		draw_line(Vector2(x, y), Vector2(x + wing, y - 3.0 + flap), Color("#35464b", 0.72), 1.5)


func _draw_crags() -> void:
	# Jagged vertical slate beyond the birdcall clue; a legible fight silhouette.
	for i in range(11):
		var x: float = 2330.0 + float(i) * 76.0
		var w: float = 104.0 + float((i * 13) % 31)
		var h: float = 82.0 + float((i * 23) % 88)
		_stone(x, ground_y + 10.0, w, h, Color("#3a4d4b" if i % 2 else "#465853"))
		var top: float = ground_y - h + 10.0
		draw_line(Vector2(x - w * 0.18, top + 12.0), Vector2(x - w * 0.10, top + 47.0), Color("#a5a491", 0.22), 1.7)
	for i in range(30):
		var x: float = 2300.0 + float(i) * 28.0
		_stone(x, ground_y + 1.0, 8.0 + float(i % 5) * 3.0, 5.0 + float((i * 7) % 11), Color("#647168"))


func _draw_cover_rock() -> void:
	# Cover matches the rifle encounter's x=2500..2580 safe interval.
	_stone(2540.0, 442.0, 123.0, 92.0, Color("#4c605d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2479, 442), Vector2(2494, 382), Vector2(2520, 349),
		Vector2(2536, 372), Vector2(2522, 418), Vector2(2509, 441),
	]), Color("#879187", 0.22))
	draw_line(Vector2(2532, 370), Vector2(2564, 411), Color("#2c4243", 0.62), 2.0)
	draw_line(Vector2(2503, 387), Vector2(2520, 372), Color("#b4ad94", 0.42), 2.0)
