extends Node2D

@export var area_name: String = "Zhinvali - Ford Ruins"
@export var area_width: float = 2200.0

func _ready() -> void:
	var world: Node = get_node_or_null("/root/WorldState")
	if world != null and world.has_method("enter_location"):
		world.call("enter_location", "zhinvali")
	queue_redraw()

func camera_bounds() -> Rect2i:
	return Rect2i(0, -380, roundi(area_width), 1660)

func _draw() -> void:
	for i in range(20):
		var t: float = float(i) / 19.0
		draw_rect(Rect2(0.0, -920.0 + float(i) * 92.0, area_width, 94.0), Color("#d7d1c5").lerp(Color("#a8a393"), t))

	# Mist and distant breach beyond the ruin.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 428.0), Vector2(280.0, 370.0), Vector2(650.0, 392.0), Vector2(1020.0, 352.0),
		Vector2(1420.0, 398.0), Vector2(1800.0, 368.0), Vector2(area_width, 398.0), Vector2(area_width, 640.0), Vector2(0.0, 640.0)
	]), Color("#7d8f8b", 0.24))
	for i in range(8):
		var x: float = 90.0 + float(i) * 260.0
		draw_circle(Vector2(x, 408.0 + sin(float(i) * 0.8) * 10.0), 98.0, Color("#f0eee4", 0.055))

	# Main vaulted chamber shell.
	draw_colored_polygon(PackedVector2Array([
		Vector2(60.0, 640.0), Vector2(60.0, 148.0), Vector2(228.0, 110.0), Vector2(432.0, 154.0),
		Vector2(620.0, 106.0), Vector2(828.0, 142.0), Vector2(1048.0, 92.0), Vector2(1262.0, 150.0),
		Vector2(1450.0, 108.0), Vector2(1646.0, 144.0), Vector2(1830.0, 124.0), Vector2(2038.0, 176.0), Vector2(2140.0, 640.0)
	]), Color("#6b6356"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(150.0, 640.0), Vector2(150.0, 194.0), Vector2(430.0, 166.0), Vector2(760.0, 162.0),
		Vector2(1080.0, 150.0), Vector2(1408.0, 174.0), Vector2(1736.0, 184.0), Vector2(1980.0, 212.0), Vector2(1980.0, 640.0)
	]), Color("#4b443a", 0.50))

	# Upper gallery remains and wall banding.
	for rect in [Rect2(286.0, 430.0, 1490.0, 16.0), Rect2(252.0, 588.0, 1610.0, 18.0)]:
		draw_rect(rect, Color("#847867", 0.88))
	for x in [420.0, 760.0, 1110.0, 1460.0, 1788.0]:
		draw_rect(Rect2(x, 244.0, 28.0, 362.0), Color("#5f5648", 0.92))
		draw_rect(Rect2(x - 8.0, 228.0, 44.0, 20.0), Color("#938571", 0.72))
		draw_rect(Rect2(x - 10.0, 410.0, 48.0, 18.0), Color("#938571", 0.68))

	# Entrance arch and back recess.
	draw_colored_polygon(PackedVector2Array([
		Vector2(222.0, 640.0), Vector2(222.0, 468.0), Vector2(340.0, 376.0), Vector2(458.0, 468.0), Vector2(458.0, 640.0)
	]), Color("#24211d", 0.97))
	draw_arc(Vector2(340.0, 470.0), 118.0, PI, TAU, 24, Color("#97886f", 0.66), 5.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1488.0, 640.0), Vector2(1488.0, 500.0), Vector2(1608.0, 430.0), Vector2(1736.0, 500.0), Vector2(1736.0, 640.0)
	]), Color("#2c2823", 0.80))
	draw_arc(Vector2(1612.0, 502.0), 122.0, PI, TAU, 22, Color("#867860", 0.46), 4.0)

	# Wall openings / niches.
	for rect in [Rect2(640.0, 292.0, 56.0, 92.0), Rect2(956.0, 248.0, 66.0, 108.0), Rect2(1268.0, 286.0, 58.0, 92.0), Rect2(1680.0, 246.0, 74.0, 110.0)]:
		draw_rect(rect, Color("#302c27", 0.78))

	# Light shafts.
	for poly in [
		PackedVector2Array([Vector2(982.0, 240.0), Vector2(1034.0, 240.0), Vector2(1130.0, 640.0), Vector2(1028.0, 640.0)]),
		PackedVector2Array([Vector2(1678.0, 248.0), Vector2(1738.0, 248.0), Vector2(1820.0, 640.0), Vector2(1710.0, 640.0)])
	]:
		draw_colored_polygon(poly, Color("#f3e6b8", 0.09))

	# Chest dais and paving.
	draw_rect(Rect2(1426.0, 570.0, 230.0, 26.0), Color("#92836d", 0.90))
	draw_rect(Rect2(1460.0, 544.0, 160.0, 28.0), Color("#7e725f", 0.95))

	# Floor, paving and cracks.
	draw_rect(Rect2(0.0, 640.0, area_width, 148.0), Color("#817563", 0.90))
	for x in [220.0, 344.0, 476.0, 612.0, 744.0, 876.0, 1010.0, 1144.0, 1278.0, 1412.0, 1546.0, 1680.0, 1814.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 30.0, 640.0), Vector2(x - 14.0, 610.0), Vector2(x + 18.0, 604.0), Vector2(x + 34.0, 640.0)
		]), Color("#998a73", 0.84))
	for seg in [
		[580.0, 612.0, 642.0, 590.0],
		[926.0, 604.0, 1002.0, 578.0],
		[1354.0, 614.0, 1418.0, 594.0],
		[1748.0, 608.0, 1804.0, 584.0]
	]:
		draw_line(Vector2(seg[0], seg[1]), Vector2(seg[2], seg[3]), Color("#5b5246", 0.55), 2.0)

	# Rubble and detail clusters.
	for x in [520.0, 612.0, 820.0, 1165.0, 1328.0, 1690.0, 1894.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 24.0, 640.0), Vector2(x - 10.0, 618.0), Vector2(x + 8.0, 608.0), Vector2(x + 28.0, 640.0)
		]), Color("#8d7f69", 0.88))
	for pos in [Vector2(636.0, 574.0), Vector2(1080.0, 560.0), Vector2(1862.0, 586.0)]:
		draw_circle(pos, 10.0, Color("#6d6558", 0.80))
		draw_circle(pos + Vector2(12.0, -6.0), 7.0, Color("#857864", 0.78))
