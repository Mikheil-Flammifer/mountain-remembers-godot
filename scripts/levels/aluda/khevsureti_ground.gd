@tool
extends Node2D
## Collision-free decorative rocky alpine pasture.
## Physical floor remains owned by the existing StaticBody2D.

@export var left_edge: float = -1200.0
@export var right_edge: float = 3100.0
@export var ground_y: float = 440.0

const EARTH := Color("#293b36")
const SLATE := Color("#46544d")
const SURFACE := Color("#8f9476")

func _draw() -> void:
	draw_rect(Rect2(left_edge, ground_y, right_edge - left_edge, 600.0), EARTH)
	draw_rect(Rect2(left_edge, ground_y, right_edge - left_edge, 7.0), SLATE)
	draw_line(Vector2(left_edge, ground_y), Vector2(right_edge, ground_y), SURFACE, 2.0)
	for i in range(int((right_edge - left_edge) / 97.0)):
		var x: float = left_edge + float(i) * 97.0 + 18.0
		var y: float = ground_y + 31.0 + float((i * 43) % 94)
		draw_line(Vector2(x, y), Vector2(x + 23.0 + float(i % 5) * 11.0, y - 4.0), Color("#9b9b80", 0.17), 1.4)
	for i in range(int((right_edge - left_edge) / 105.0)):
		var x: float = left_edge + float(i) * 105.0 + float((i * 37) % 60)
		var width: float = 8.0 + float((i * 13) % 15)
		var height: float = 4.0 + float((i * 17) % 10)
		if i % 5 == 0:
			width *= 1.8
			height *= 1.4
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - width, ground_y + 2.0),
			Vector2(x - width * 0.62, ground_y - height * 0.69),
			Vector2(x - width * 0.12, ground_y - height),
			Vector2(x + width * 0.67, ground_y - height * 0.7),
			Vector2(x + width, ground_y + 2.0),
		]), Color("#69746b" if i % 2 else "#515e5a"))
		draw_line(Vector2(x - width * 0.55, ground_y - height * 0.56), Vector2(x - width * 0.13, ground_y - height + 2.0), Color("#b0aa8e", 0.46), 1.4)
	for i in range(int((right_edge - left_edge) / 38.0)):
		if i % 4 == 0:
			continue
		var x: float = left_edge + float(i) * 38.0 + float((i * 19) % 25)
		var h: float = 4.0 + float((i * 7) % 7)
		draw_line(Vector2(x, ground_y), Vector2(x - 3.0, ground_y - h), Color("#a6a984", 0.53), 1.1)
		draw_line(Vector2(x, ground_y), Vector2(x + 3.7, ground_y - h * 0.77), Color("#b2a982", 0.47), 1.0)
	for center_x in [310.0, 905.0, 1540.0, 2205.0, 2730.0]:
		for j in range(6):
			var x: float = center_x + float(j - 3) * 11.0
			var y: float = ground_y + 8.0 + float((j * 9) % 24)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 8.0, y + 8.0),
				Vector2(x - 3.0, y - 4.0),
				Vector2(x + 8.0, y - 2.0),
				Vector2(x + 12.0, y + 9.0),
			]), Color("#58665e" if j % 2 else "#788077"))
