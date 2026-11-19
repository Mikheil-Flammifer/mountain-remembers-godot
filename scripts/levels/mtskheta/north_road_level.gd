extends Node2D
# SHARED_WARM_GREEN_LANDSCAPE
const Landscape = preload("res://scripts/levels/mtskheta/shared/mtskheta_landscape.gd")

## Mtskheta's southern foothill road, late summer / early autumn.
## The forest becomes cold and sparse only in later highland regions.
## Purely visual: does not touch wolf placement, collisions, or transitions.

const SKY := Color("#e8c7a0")
const HAZE := Color("#e3af80")
const FAR_HILL := Color("#bd9272")
const MID_HILL := Color("#988363")
const NEAR_HILL := Color("#6e7253")
const EARTH := Color("#755b46")
const PATH := Color("#ae8a64")
const PATH_LIGHT := Color("#c5a17a")
const WOOD := Color("#614731")


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _draw() -> void:
	Landscape.draw_landscape(self, 2400.0, 650.0, 0.92)

	# Faint ridge lines and distant farm terraces.
	for i in range(9):
		var x := 130.0 + float(i) * 290.0
		draw_line(Vector2(x, 470), Vector2(x + 85, 455), Color("#d1aa83", 0.42), 2.0)

	# Warm dirt road at the existing solid ground height (650).
	draw_rect(Rect2(0, 650, 2400, 170), EARTH)
	draw_rect(Rect2(0, 641, 2400, 13), PATH)
	draw_line(Vector2(0, 641), Vector2(2400, 641), PATH_LIGHT, 2.0)
	for i in range(53):
		var sx := 29.0 + float(i) * 47.0
		var sy := 660.0 + float(i % 4) * 21.0
		draw_line(Vector2(sx, sy), Vector2(sx + 15, sy - 2), Color("#a28160", 0.55), 2.0)

	# Staggered broadleaf trees, warm hazel, oak and chestnut colors.
	# All drawn BEHIND Xizane and the wolf.
	_draw_tree(215.0, 649.0, 0.90, 1)
	_draw_tree(545.0, 648.0, 1.15, 0)
	_draw_tree(875.0, 651.0, 0.98, 2)
	_draw_tree(1165.0, 648.0, 0.84, 1)
	_draw_tree(1700.0, 648.0, 1.08, 0)
	_draw_tree(2090.0, 648.0, 1.03, 2)
	_draw_tree(2335.0, 648.0, 0.72, 1)

	# Broken roadside wall and scattered warm stone.
	for x in [315.0, 680.0, 1010.0, 1830.0, 2180.0]:
		_draw_stone(x, 640.0)

	# Wooden road sign kept left of the wolf encounter.
	draw_rect(Rect2(427, 515, 13, 135), WOOD)
	draw_colored_polygon(PackedVector2Array([
		Vector2(377, 522), Vector2(482, 522),
		Vector2(507, 543), Vector2(482, 564), Vector2(377, 564)
	]), Color("#98734c"))
	draw_line(Vector2(387, 534), Vector2(475, 534), Color("#d1ae79"), 2.0)

	# Wild grass patches at the edge of the warm road.
	for i in range(49):
		var x := 23.0 + float(i) * 49.0
		var h := 8.0 + float(i % 5) * 3.0
		draw_line(Vector2(x, 647), Vector2(x - 4, 647 - h), Color("#8f874e"), 2.0)
		draw_line(Vector2(x, 647), Vector2(x + 5, 647 - h * 0.8), Color("#a79b5f"), 1.5)


func _draw_tree(x: float, base_y: float, scale_value: float, variety: int) -> void:
	var crown_y: float = base_y - 155.0 * scale_value
	var trunk_w: float = 20.0 * scale_value
	draw_rect(Rect2(x - trunk_w * 0.5, base_y - 126.0 * scale_value, trunk_w, 126.0 * scale_value), WOOD)
	draw_line(Vector2(x, base_y - 90.0 * scale_value), Vector2(x - 45.0 * scale_value, crown_y + 20.0 * scale_value), Color("#715036"), 9.0 * scale_value)
	draw_line(Vector2(x, base_y - 91.0 * scale_value), Vector2(x + 42.0 * scale_value, crown_y + 14.0 * scale_value), Color("#715036"), 8.0 * scale_value)
	var dark := Color("#6a7549")
	var middle := Color("#8b8b4e")
	var light := Color("#b19a55")
	if variety == 1:
		dark = Color("#79704a")
		middle = Color("#a18b50")
		light = Color("#c0a169")
	elif variety == 2:
		dark = Color("#806044")
		middle = Color("#a97743")
		light = Color("#cb965c")
	# Broadleaf crowns in distinct leaf clusters, not conifers.
	draw_circle(Vector2(x, crown_y), 67.0 * scale_value, dark)
	draw_circle(Vector2(x - 49.0 * scale_value, crown_y + 19.0 * scale_value), 47.0 * scale_value, middle)
	draw_circle(Vector2(x + 48.0 * scale_value, crown_y + 14.0 * scale_value), 48.0 * scale_value, dark)
	draw_circle(Vector2(x - 9.0 * scale_value, crown_y - 38.0 * scale_value), 42.0 * scale_value, middle)
	draw_circle(Vector2(x + 28.0 * scale_value, crown_y - 21.0 * scale_value), 38.0 * scale_value, light)
	# Leaf flecks add texture without requiring separate sprites.
	for i in range(13):
		var angle := float(i) * TAU / 13.0
		var dx := cos(angle) * 52.0 * scale_value
		var dy := sin(angle) * 36.0 * scale_value
		draw_circle(Vector2(x + dx, crown_y + dy), 5.0 * scale_value, Color(light, 0.55))


func _draw_stone(x: float, ground_y: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 17, ground_y), Vector2(x - 15, ground_y - 16),
		Vector2(x - 2, ground_y - 23), Vector2(x + 19, ground_y - 14),
		Vector2(x + 24, ground_y)
	]), Color("#978470"))
	draw_line(Vector2(x - 2, ground_y - 21), Vector2(x + 5, ground_y - 3), Color("#c3a58a"), 2.0)
