@tool
@icon("res://assets/icons/castle/meat_platter.svg")
class_name CastleMeatPlatter
extends CastleProp
## Wooden platter with roast mutton and greens. Stands on the table top.


func _draw_prop() -> void:
	poly(PackedVector2Array([Vector2(-60, 0), Vector2(60, 0), Vector2(68, -8), Vector2(-68, -8)]), Color(0.4, 0.25, 0.13))
	draw_line(Vector2(-68, -8), Vector2(68, -8), Color(0.55, 0.37, 0.2), 2.0)
	var pts := PackedVector2Array()
	for i in 14:
		var a := PI + PI * i / 13.0
		pts.append(Vector2(cos(a) * 46, -8 + sin(a) * 26))
	poly(pts, Color(0.5, 0.24, 0.1))
	for i in 10:
		draw_circle(Vector2(rng.randf_range(-36, 36), rng.randf_range(-28, -12)), rng.randf_range(3, 7), Color(0.62, 0.3, 0.12, 0.8))
	draw_circle(Vector2(-14, -24), 8, Color(0.78, 0.45, 0.2, 0.7))
	draw_line(Vector2(30, -20), Vector2(62, -40), Color(0.92, 0.88, 0.78), 6.0)
	draw_circle(Vector2(63, -42), 6, Color(0.95, 0.92, 0.84))
	for i in 5:
		var p := Vector2(-56 + i * 7, -10)
		poly(PackedVector2Array([p, p + Vector2(-4, -10), p + Vector2(3, -14), p + Vector2(5, -2)]), Color(0.25, 0.5, 0.18))
