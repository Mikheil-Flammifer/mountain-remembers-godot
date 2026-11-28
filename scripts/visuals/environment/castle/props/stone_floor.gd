@tool
@icon("res://assets/icons/castle/stone_floor.svg")
class_name CastleStoneFloor
extends CastleProp
## Flagstone floor seen in slight perspective; rows get larger toward the viewer.

@export var size := Vector2(1400, 90):
	set(value):
		size = value
		queue_redraw()


func _draw_prop() -> void:
	var left := -size.x * 0.5
	draw_rect(Rect2(left, -size.y, size.x, size.y), Color(0.2, 0.17, 0.14))
	var y := -size.y
	var row := 0
	while y < 0.0:
		var h := 14.0 + row * 9.0
		var x := left - rng.randf_range(0, 60)
		while x < -left:
			var w := rng.randf_range(70, 140) + row * 20.0
			stone_block(Rect2(x + 2, y + 1, w - 4, h - 2), Color(0.38, 0.34, 0.3))
			x += w
		y += h
		row += 1
	draw_rect(Rect2(left, -size.y, size.x, 8), Color(0, 0, 0, 0.35))
