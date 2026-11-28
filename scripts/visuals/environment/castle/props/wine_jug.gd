@tool
@icon("res://assets/icons/castle/wine_jug.svg")
class_name CastleWineJug
extends CastleProp
## Clay jug (doki) with a painted band. Stands on the table top.


func _draw_prop() -> void:
	var clay := Color(0.62, 0.32, 0.18)
	draw_arc(Vector2(16, -44), 13, -PI * 0.6, PI * 0.5, 12, clay.darkened(0.2), 5.0)
	var pts := PackedVector2Array([Vector2(-11, 0), Vector2(11, 0), Vector2(20, -20), Vector2(18, -40), Vector2(8, -54), Vector2(9, -64), Vector2(13, -68), Vector2(-11, -68), Vector2(-8, -54), Vector2(-18, -40), Vector2(-20, -20)])
	poly(pts, clay)
	poly(PackedVector2Array([Vector2(-11, 0), Vector2(-2, 0), Vector2(-10, -20), Vector2(-8, -40), Vector2(-18, -40), Vector2(-20, -20)]), clay.darkened(0.2))
	draw_line(Vector2(8, -10), Vector2(14, -38), clay.lightened(0.25), 3.0)
	draw_line(Vector2(-19, -32), Vector2(19, -32), Color(0.2, 0.12, 0.08), 3.0)
	for i in 6:
		draw_circle(Vector2(-15 + i * 6, -27), 1.5, Color(0.9, 0.82, 0.6))
	draw_line(Vector2(-12, -68), Vector2(14, -68), clay.lightened(0.15), 2.0)
