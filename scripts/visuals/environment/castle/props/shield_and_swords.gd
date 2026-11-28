@tool
@icon("res://assets/icons/castle/shield_and_swords.svg")
class_name CastleShieldAndSwords
extends CastleProp
## Round Khevsur shield (pari) over two crossed swords, hung on the wall.


func _draw_prop() -> void:
	var c := Vector2(0, -70)
	for s in [-1.0, 1.0]:
		var a := c + Vector2(-80 * s, 70)
		var b := c + Vector2(80 * s, -70)
		draw_line(a, b, Color(0.72, 0.74, 0.76), 6.0)
		draw_line(a, b, Color(0.9, 0.92, 0.95), 1.5)
		var hilt := a + (a - b).normalized() * 4
		var cross := (b - a).normalized().orthogonal() * 12
		draw_line(a - cross, a + cross, Color(0.6, 0.5, 0.25), 4.0)
		draw_line(a, hilt + (a - b).normalized() * 22, Color(0.3, 0.18, 0.1), 6.0)
		draw_circle(hilt + (a - b).normalized() * 24, 4, Color(0.6, 0.5, 0.25))
	draw_circle(c + Vector2(3, 4), 52, Color(0, 0, 0, 0.35))
	draw_circle(c, 52, Color(0.32, 0.22, 0.14))
	for i in 3:
		draw_arc(c, 50 - i * 14, 0, TAU, 40, Color(0.55, 0.5, 0.45), 4.0)
	for i in 16:
		var p := c + Vector2.RIGHT.rotated(TAU * i / 16.0) * 43
		draw_circle(p, 3, Color(0.75, 0.73, 0.68))
		draw_circle(p - Vector2(1, 1), 1, Color(1, 1, 1, 0.7))
	draw_circle(c, 15, Color(0.6, 0.58, 0.54))
	draw_circle(c - Vector2(4, 4), 6, Color(0.85, 0.84, 0.8))
	draw_arc(c, 15, 0, TAU, 20, Color(0.25, 0.24, 0.22), 2.0)
	for i in 4:
		var d := Vector2.RIGHT.rotated(TAU * i / 4.0 + PI / 4)
		draw_line(c + d * 18, c + d * 30, Color(0.7, 0.15, 0.12), 4.0)
