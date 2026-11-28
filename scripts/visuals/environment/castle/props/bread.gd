@tool
@icon("res://assets/icons/castle/bread.svg")
class_name CastleBread
extends CastleProp
## Round mountain loaves on a cloth. Stands on the table top.


func _draw_prop() -> void:
	poly(PackedVector2Array([Vector2(-44, 0), Vector2(44, 0), Vector2(36, -8), Vector2(-36, -8)]), Color(0.88, 0.85, 0.78))
	for i in 3:
		draw_line(Vector2(-40 + i * 4, -3), Vector2(40 - i * 4, -3), Color(0.7, 0.15, 0.12), 1.0)
	for i in 3:
		var c := Vector2(-22 + i * 22, -14 - (6 if i == 1 else 0))
		draw_circle(c + Vector2(0, 3), 17, Color(0.45, 0.27, 0.1))
		draw_circle(c, 17, vary(Color(0.76, 0.5, 0.22), 0.06))
		draw_circle(c + Vector2(-4, -5), 9, Color(0.86, 0.64, 0.34, 0.7))
		for k in 3:
			draw_line(c + Vector2(-9, -6 + k * 6), c + Vector2(9, -8 + k * 6), Color(0.5, 0.3, 0.12), 1.5)
		for k in 6:
			draw_circle(c + Vector2(rng.randf_range(-11, 11), rng.randf_range(-11, 9)), 0.8, Color(0.95, 0.9, 0.75))
