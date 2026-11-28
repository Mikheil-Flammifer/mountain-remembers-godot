@tool
@icon("res://assets/icons/castle/chief_chair.svg")
class_name CastleChiefChair
extends CastleProp
## The head of the table's high carved chair with a sheepskin over the back.
## Place it behind the character who sits in it.


func _draw_prop() -> void:
	var dark := Color(0.3, 0.18, 0.1)
	for s in [-1.0, 1.0]:
		wood_plank(Rect2(s * 62 - 9, -250, 18, 250), dark, true)
		poly(PackedVector2Array([Vector2(s * 62 - 10, -250), Vector2(s * 62, -278), Vector2(s * 62 + 10, -250)]), Color(0.45, 0.3, 0.16))
		draw_circle(Vector2(s * 62, -280), 7, Color(0.7, 0.55, 0.25))
	wood_plank(Rect2(-54, -246, 108, 150), Color(0.38, 0.23, 0.12), true)
	var c := Vector2(0, -205)
	poly(PackedVector2Array([c + Vector2(0, -28), c + Vector2(28, 0), c + Vector2(0, 28), c + Vector2(-28, 0)]), Color(0.25, 0.14, 0.08))
	for k in 8:
		var d := Vector2.RIGHT.rotated(TAU * k / 8.0)
		draw_line(c, c + d * 22, Color(0.75, 0.58, 0.3), 2.5)
	draw_circle(c, 6, Color(0.8, 0.62, 0.3))
	for i in 6:
		draw_circle(Vector2(-44 + i * 17.6, -238), 3, Color(0.7, 0.55, 0.25))
	var wool := PackedVector2Array([Vector2(-50, -170), Vector2(50, -170), Vector2(54, -90), Vector2(-54, -90)])
	poly(wool, Color(0.86, 0.82, 0.72))
	for i in 60:
		var p := Vector2(rng.randf_range(-50, 50), rng.randf_range(-168, -94))
		draw_arc(p, rng.randf_range(2, 4), 0, PI * 1.5, 6, Color(0.7, 0.65, 0.55), 1.2)
	wood_plank(Rect2(-72, -96, 144, 14), Color(0.42, 0.27, 0.14))
	for s in [-1.0, 1.0]:
		draw_line(Vector2(s * 72, -100), Vector2(s * 72, -150), dark, 8.0)
		draw_circle(Vector2(s * 72, -152), 7, Color(0.7, 0.55, 0.25))
