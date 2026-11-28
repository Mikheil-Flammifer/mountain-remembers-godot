@tool
extends Node2D
## Readable evidence props within the Shepherds' Fold scene.
## Local coordinates use the fold origin at world X=-150; no collision.

const LEATHER := Color("#6d5243")
const CORD := Color("#aa8c6b")
const SPLINTER := Color("#d3bd92")
const DIRT := Color("#42514a")


func _draw() -> void:
	# A sliced leather halter tied to the left fence rail (world x~295).
	var x: float = 445.0
	draw_line(Vector2(x - 18, 379), Vector2(x + 16, 384), CORD, 3.0)
	draw_arc(Vector2(x, 394), 13.0, 0.16, PI * 1.83, 24, LEATHER, 3.0, true)
	draw_line(Vector2(x + 10, 402), Vector2(x + 16, 419), LEATHER, 4.0)
	draw_line(Vector2(x + 19, 422), Vector2(x + 26, 429), LEATHER, 3.0)
	draw_line(Vector2(x + 16, 419), Vector2(x + 19, 422), SPLINTER, 1.4)
	draw_circle(Vector2(x - 3, 381), 2.8, Color("#bdac89"))

	# The smashed gate (world x~570): a splintered crossbar and scuffed earth.
	var gate_x: float = 720.0
	draw_line(Vector2(gate_x - 32, 390), Vector2(gate_x + 30, 426), Color("#59493b"), 6.0, true)
	draw_line(Vector2(gate_x - 32, 389), Vector2(gate_x + 10, 415), Color("#a38e6c", 0.62), 1.4)
	draw_colored_polygon(PackedVector2Array([
		Vector2(gate_x + 24, 422), Vector2(gate_x + 37, 431),
		Vector2(gate_x + 27, 429), Vector2(gate_x + 22, 428)
	]), SPLINTER)
	draw_line(Vector2(gate_x + 6, 426), Vector2(gate_x + 29, 434), Color("#a19370", 0.58), 1.0)
	draw_line(Vector2(gate_x + 15, 435), Vector2(gate_x + 39, 437), DIRT, 2.0)
