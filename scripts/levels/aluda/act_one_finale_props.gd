@tool
extends Node2D
## Additional Act I finale landmarks. Collision and shoot-cover logic remain
## in ActOneTracking and ActOneMutsalDuel, not in this painted environment.

func _draw() -> void:
	_draw_mutsal_cover()
	_draw_road_out()


func _draw_mutsal_cover() -> void:
	var x: float = 2930.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 87, 444), Vector2(x - 69, 387), Vector2(x - 42, 353),
		Vector2(x + 8, 348), Vector2(x + 62, 382), Vector2(x + 77, 444)
	]), Color("#41575a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 69, 387), Vector2(x - 42, 353), Vector2(x + 8, 348),
		Vector2(x - 5, 423), Vector2(x - 61, 441)
	]), Color("#82918b", 0.45))
	draw_line(Vector2(x + 15, 361), Vector2(x + 5, 418), Color("#1c3539", 0.49), 2.0)
	draw_line(Vector2(x - 48, 377), Vector2(x - 28, 369), Color("#c2c0a6", 0.38), 1.7)
	for i in range(8):
		var px: float = x + 83.0 + float(i) * 26.0
		draw_line(Vector2(px, 439), Vector2(px + 10, 433), Color("#a5a48a", 0.28), 1.4)


func _draw_road_out() -> void:
	# The exit is reachable only after the duel and a deliberate hand choice.
	draw_colored_polygon(PackedVector2Array([
		Vector2(3450, 440), Vector2(3465, 395), Vector2(3500, 356),
		Vector2(3555, 330), Vector2(3670, 354), Vector2(3720, 395),
		Vector2(3760, 440)
	]), Color("#3a4e52", 0.45))
	draw_colored_polygon(PackedVector2Array([
		Vector2(3470, 439), Vector2(3550, 433), Vector2(3610, 430),
		Vector2(3790, 441), Vector2(3790, 446), Vector2(3470, 447)
	]), Color("#b3a48a", 0.2))
	for i in range(16):
		var px: float = 3400.0 + float(i) * 28.0
		var py: float = 439.0
		draw_line(Vector2(px, py), Vector2(px + 14, py - 7.0), Color("#849388", 0.22), 1.4)
	# Boundary cairns pointing toward the coming night road.
	for px in [3500.0, 3755.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(px - 22, 441), Vector2(px - 15, 424),
			Vector2(px + 16, 423), Vector2(px + 21, 441)
		]), Color("#60716d"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(px - 12, 422), Vector2(px - 7, 403),
			Vector2(px + 11, 405), Vector2(px + 14, 422)
		]), Color("#76867a"))
		draw_circle(Vector2(px + 1, 398), 6.0, Color("#a5ad9a"))
