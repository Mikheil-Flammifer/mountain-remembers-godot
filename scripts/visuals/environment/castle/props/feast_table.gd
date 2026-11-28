@tool
@icon("res://assets/icons/castle/feast_table.svg")
class_name CastleFeastTable
extends CastleProp
## Long oak feast table. Its front panel hides the legs of people sitting behind it,
## so place seated characters just behind the table. Food goes on top at y = -height.

@export var length := 860.0:
	set(value):
		length = value
		queue_redraw()
@export var height := 105.0:
	set(value):
		height = value
		queue_redraw()


func _draw_prop() -> void:
	var l := length * 0.5
	poly(PackedVector2Array([Vector2(-l + 10, -height - 18), Vector2(l - 10, -height - 18), Vector2(l + 6, -height), Vector2(-l - 6, -height)]), Color(0.5, 0.34, 0.2))
	var x := -l
	while x < l - 10:
		var pw := rng.randf_range(60, 110)
		draw_line(Vector2(x, -height - 1), Vector2(x + 6, -height - 17), Color(0.33, 0.22, 0.12), 1.0)
		x += pw
	for i in 3:
		wood_plank(Rect2(-l - 6, -height + i * 9, length + 12, 9), Color(0.46, 0.3, 0.17))
	draw_rect(Rect2(-l - 6, -height + 27, length + 12, height - 27), Color(0.27, 0.17, 0.1))
	for s in [-1.0, 1.0]:
		wood_plank(Rect2(s * (l - 40) - 18, -height + 27, 36, height - 27), Color(0.38, 0.24, 0.13), true)
	var panels := int(length / 120.0)
	for i in panels:
		var px := -l + 40 + (length - 80) * (i + 0.5) / panels
		var r := Rect2(px - 40, -height + 40, 80, height - 55)
		draw_rect(r, Color(0.32, 0.2, 0.11))
		draw_rect(r, Color(0.2, 0.12, 0.07), false, 2.0)
		var c := r.get_center()
		for k in 4:
			var d := Vector2.RIGHT.rotated(TAU * k / 4.0) * 14
			draw_line(c, c + d, Color(0.55, 0.38, 0.22), 3.0)
			draw_circle(c + d, 3.5, Color(0.55, 0.38, 0.22))
		draw_arc(c, 22, 0, TAU, 24, Color(0.5, 0.34, 0.2), 1.5)
	draw_rect(Rect2(-l - 6, -6, length + 12, 6), Color(0, 0, 0, 0.4))
