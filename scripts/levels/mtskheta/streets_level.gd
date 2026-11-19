extends Node2D
# SHARED_WARM_GREEN_LANDSCAPE
const Landscape = preload("res://scripts/levels/mtskheta/shared/mtskheta_landscape.gd")
## Historic Mtskheta-inspired stone-lane silhouettes. Drawing only.
## This is an artistic interpretation, not a reconstruction of a specific century.

const SKY = Color("#d9c4a5")
const HILLS = Color("#96866c")
const WALL = Color("#ad967c")
const JOINT = Color("#625e57")
const ROOF = Color("#64524a")
const WOOD = Color("#58483b")

func _ready() -> void:
	z_index = -10
	queue_redraw()

func _draw() -> void:
	_draw_hills()
	_draw_cathedral_silhouette()
	_draw_ground()
	for house: Dictionary in [
		{"x": 30.0, "w": 280.0, "top": 384.0},
		{"x": 345.0, "w": 295.0, "top": 407.0},
		{"x": 1220.0, "w": 290.0, "top": 388.0},
		{"x": 1570.0, "w": 260.0, "top": 415.0},
		{"x": 1930.0, "w": 305.0, "top": 380.0},
	]:
		_draw_house(float(house["x"]), float(house["w"]), float(house["top"]))
	_draw_courtyard_wall(695.0, 182.0)
	_draw_courtyard_wall(1060.0, 145.0)
	_draw_cathedral_arch(970.0)
	_draw_vines(420.0, 370.0)
	_draw_vines(1645.0, 380.0)
	_draw_well(1830.0)

func _draw_hills() -> void:
	Landscape.draw_landscape(self, 2400.0, 650.0, 0.45)

func _draw_cathedral_silhouette() -> void:
	# A distant Svetitskhoveli-inspired church dome, visible above the old lanes.
	var x: float = 930.0
	draw_rect(Rect2(x - 150, 351, 300, 225), Color("#77766f"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 178, 365), Vector2(x, 304), Vector2(x + 178, 365)
	]), Color("#5f5b54"))
	draw_rect(Rect2(x - 67, 246, 134, 105), Color("#6e6a60"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 76, 251), Vector2(x, 157), Vector2(x + 76, 251)
	]), Color("#514f4b"))
	draw_line(Vector2(x, 155), Vector2(x, 131), Color("#514f4b"), 4)
	draw_line(Vector2(x - 10, 140), Vector2(x + 10, 140), Color("#514f4b"), 3)
	for k: int in range(3):
		draw_rect(Rect2(x - 110 + k * 95, 408, 26, 67), Color("#464844"))

func _draw_ground() -> void:
	draw_rect(Rect2(0, 637, 2400, 180), Color("#806b56"))
	draw_rect(Rect2(0, 632, 2400, 9), Color("#c3a787"))
	# Worn joints suggest paving without cluttering the playable silhouette.
	for row: int in range(7):
		var yy: float = 657.0 + row * 23.0
		draw_line(Vector2(0, yy), Vector2(2400, yy), Color("#4a4a43"), 1.0)
		for i: int in range(37):
			var xx: float = i * 70.0 + (34.0 if row % 2 == 1 else 0.0)
			draw_line(Vector2(xx, yy), Vector2(xx + 5, yy + 22), Color("#4a4a43"), 1.0)

func _draw_house(x: float, w: float, top: float) -> void:
	draw_rect(Rect2(x, top, w, 650.0 - top), WALL)
	_draw_stone_courses(Rect2(x, top, w, 650 - top))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 17, top + 5), Vector2(x + w * 0.5, top - 86),
		Vector2(x + w + 15, top + 5)
	]), ROOF)
	# Parallel roof tile strokes.
	for i: int in range(5):
		var xx: float = x + 31 + i * (w - 58) / 5.0
		draw_line(Vector2(xx, top - 20), Vector2(xx + 27, top - 5), Color("#90705d"), 2.0)
	# Recessed windows, heavy wooden shutters, and timber balcony.
	for k: int in range(2):
		var wx: float = x + 38 + k * (w - 105)
		draw_rect(Rect2(wx, top + 56, 40, 57), Color("#414846"))
		draw_rect(Rect2(wx - 5, top + 53, 50, 64), WOOD, false, 4.0)
	draw_rect(Rect2(x + w * 0.33, 550, 55, 100), Color("#463e37"))
	draw_rect(Rect2(x + 15, top + 145, w - 30, 10), WOOD)
	for k: int in range(7):
		var bx: float = x + 23 + k * (w - 46) / 6.0
		draw_line(Vector2(bx, top + 155), Vector2(bx, top + 193), WOOD, 4)
	draw_line(Vector2(x + 18, top + 192), Vector2(x + w - 18, top + 192), WOOD, 5)

func _draw_stone_courses(rect: Rect2) -> void:
	var row: int = 0
	var yy: float = rect.position.y + 18.0
	while yy < rect.end.y:
		draw_line(Vector2(rect.position.x, yy), Vector2(rect.end.x, yy), JOINT, 1.0)
		var xx: float = rect.position.x + (32.0 if row % 2 == 0 else 0.0)
		while xx < rect.end.x:
			draw_line(Vector2(xx, yy), Vector2(xx, minf(yy + 32.0, rect.end.y)), JOINT, 1.0)
			xx += 69.0
		yy += 34.0
		row += 1

func _draw_courtyard_wall(x: float, w: float) -> void:
	var rect := Rect2(x, 551, w, 99)
	draw_rect(rect, Color("#867d71"))
	_draw_stone_courses(rect)
	draw_rect(Rect2(x - 8, 537, w + 16, 16), Color("#9a8f7e"))
	for k: int in range(2):
		draw_rect(Rect2(x + 24 + k * (w - 48), 516, 11, 23), Color("#756b60"))

func _draw_cathedral_arch(x: float) -> void:
	# The scripted cathedral interaction remains at x=970, unchanged.
	draw_rect(Rect2(x - 87, 456, 26, 194), Color("#7e7367"))
	draw_rect(Rect2(x + 61, 456, 26, 194), Color("#7e7367"))
	draw_rect(Rect2(x - 104, 435, 208, 30), Color("#9f907d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 92, 455), Vector2(x - 78, 410),
		Vector2(x, 382), Vector2(x + 78, 410), Vector2(x + 92, 455)
	]), Color("#827669"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 60, 455), Vector2(x - 42, 417),
		Vector2(x, 400), Vector2(x + 42, 417), Vector2(x + 60, 455)
	]), Color("#4d514d"))
	for col: float in [x - 70.0, x + 70.0]:
		draw_line(Vector2(col, 486), Vector2(col, 623), Color("#554e48"), 2)

func _draw_vines(x: float, y: float) -> void:
	for k: int in range(4):
		var stem_x: float = x + 19.0 * k
		draw_line(Vector2(stem_x, y), Vector2(stem_x + 16, y + 112), Color("#525c49"), 3)
		for j: int in range(4):
			draw_circle(Vector2(stem_x - 4 + (j % 2) * 16, y + 17 + j * 23), 9, Color("#656f54"))

func _draw_well(x: float) -> void:
	draw_rect(Rect2(x, 584, 77, 52), Color("#887c69"))
	for k: int in range(3):
		draw_line(Vector2(x, 598 + k * 13), Vector2(x + 77, 598 + k * 13), JOINT, 1)
	draw_line(Vector2(x + 9, 583), Vector2(x + 9, 500), WOOD, 5)
	draw_line(Vector2(x + 68, 583), Vector2(x + 68, 500), WOOD, 5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 5, 501), Vector2(x + 38, 471), Vector2(x + 83, 501)
	]), ROOF)
	draw_line(Vector2(x + 38, 501), Vector2(x + 38, 557), Color("#4c473e"), 2)
