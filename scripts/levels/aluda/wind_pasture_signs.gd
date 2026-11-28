@tool
extends Node2D
## Foreground readings for Wind-cut Pasture, positioned relative to X=650.
## All marks are visual-only; gameplay interactions remain on ActOneTracking.

@export var ground_y: float = 440.0

const SHALE := Color("#526760")
const LIGHT := Color("#b2b09a")
const DIRT := Color("#3f534c")


func _draw() -> void:
	_draw_iron_scrape()
	_draw_ridge_ledge()
	_draw_gully_decoy()


func _draw_iron_scrape() -> void:
	# Local x=250 / world x=900. Iron has scored the upper face of shale.
	var x: float = 250.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 48, ground_y + 2),
		Vector2(x - 30, ground_y - 20),
		Vector2(x - 6, ground_y - 32),
		Vector2(x + 32, ground_y - 18),
		Vector2(x + 45, ground_y + 2)
	]), SHALE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 31, ground_y - 20),
		Vector2(x - 7, ground_y - 32),
		Vector2(x + 6, ground_y - 22),
		Vector2(x - 13, ground_y - 9)
	]), Color(LIGHT, 0.33))
	draw_line(Vector2(x - 19, ground_y - 19), Vector2(x + 24, ground_y - 11), Color("#c6d0c0", 0.9), 2.0, true)
	draw_line(Vector2(x - 12, ground_y - 14), Vector2(x + 18, ground_y - 9), Color("#1c3034", 0.6), 1.2)
	for i in range(8):
		var p: float = float(i)
		draw_line(Vector2(x - 38 + 10*p, ground_y - 2), Vector2(x - 32 + 10*p, ground_y + 2), Color(DIRT, 0.44), 1.0)


func _draw_ridge_ledge() -> void:
	# Local x=510 / world x=1160. Upper ledge is the correct reading.
	var x: float = 510.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 57, ground_y + 2),
		Vector2(x - 39, ground_y - 19),
		Vector2(x - 14, ground_y - 23),
		Vector2(x + 23, ground_y - 29),
		Vector2(x + 58, ground_y - 12),
		Vector2(x + 60, ground_y + 2)
	]), Color("#677b6c", 0.63))
	draw_line(Vector2(x - 45, ground_y - 14), Vector2(x + 39, ground_y - 18), Color("#e0d6b5", 0.37), 2.0)
	# Stone marker already appears in the shared area art; add a lichen seam.
	draw_line(Vector2(x - 12, ground_y - 33), Vector2(x - 2, ground_y - 45), Color("#a2ae82", 0.6), 2.0)
	draw_circle(Vector2(x - 7, ground_y - 39), 2.4, Color("#b2b88e", 0.67))
	for i in range(5):
		var sx: float = x - 29 + float(i)*11.0
		draw_line(Vector2(sx, ground_y - 6), Vector2(sx + 9, ground_y - 8), Color(LIGHT, 0.47), 1.0)


func _draw_gully_decoy() -> void:
	# Local x=570 / world x=1220. Goat marks turn toward the lower gully.
	var x: float = 570.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 29, ground_y - 4),
		Vector2(x - 5, ground_y + 6),
		Vector2(x + 12, ground_y + 5),
		Vector2(x + 34, ground_y - 5),
		Vector2(x + 29, ground_y + 2),
		Vector2(x - 9, ground_y + 11)
	]), Color(DIRT, 0.62))
	for i in range(4):
		var sx: float = x - 23 + float(i) * 13.0
		# Two small split marks unlike a broad horseshoe.
		draw_line(Vector2(sx, ground_y - 6), Vector2(sx + 4, ground_y - 1), Color("#202f2e", 0.79), 2.0)
		draw_line(Vector2(sx + 7, ground_y - 6), Vector2(sx + 4, ground_y - 1), Color("#202f2e", 0.79), 2.0)
	draw_line(Vector2(x + 3, ground_y - 13), Vector2(x + 32, ground_y - 18), Color("#a4ad96", 0.23), 1.0)
