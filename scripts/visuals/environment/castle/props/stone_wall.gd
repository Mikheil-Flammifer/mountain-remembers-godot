@tool
@icon("res://assets/icons/castle/stone_wall.svg")
class_name CastleStoneWall
extends CastleProp
## Dry-laid Khevsur slate/stone wall with soot darkening near the ceiling.

@export var size := Vector2(1400, 700):
	set(value):
		size = value
		queue_redraw()
@export var stone_color := Color(0.45, 0.41, 0.36)


func _draw_prop() -> void:
	var left := -size.x * 0.5
	draw_rect(Rect2(left, -size.y, size.x, size.y), Color(0.16, 0.13, 0.11))
	var y := 0.0
	while y > -size.y:
		var course_h := rng.randf_range(26, 44)
		var x := left - rng.randf_range(0, 40)
		while x < -left:
			var w := rng.randf_range(48, 110)
			stone_block(Rect2(x + 2, y - course_h + 2, w - 4, course_h - 4), stone_color)
			x += w
		y -= course_h
	for i in 10:
		var k := i / 10.0
		draw_rect(Rect2(left, -size.y, size.x, size.y * (0.45 - k * 0.04)), Color(0.05, 0.03, 0.02, 0.06))
	draw_rect(Rect2(left, -24, size.x, 24), Color(0, 0, 0, 0.25))
