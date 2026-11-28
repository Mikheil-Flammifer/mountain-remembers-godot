@tool
@icon("res://assets/icons/castle/drinking_horn.svg")
class_name CastleDrinkingHorn
extends CastleProp
## Silver-rimmed drinking horn (kantsi) on a small stand. Stands on the table top.


func _draw_prop() -> void:
	draw_line(Vector2(-8, 0), Vector2(-8, -10), Color(0.6, 0.58, 0.55), 2.0)
	draw_line(Vector2(10, 0), Vector2(10, -10), Color(0.6, 0.58, 0.55), 2.0)
	var pts := PackedVector2Array()
	var back := PackedVector2Array()
	for i in 12:
		var t := i / 11.0
		var spine := Vector2(-30 + t * 52, -10 - sin(t * PI * 0.9) * 10 - t * 26)
		var w := 2.0 + t * 9.0
		pts.append(spine + Vector2(0, w))
		back.append(spine - Vector2(0, w))
	back.reverse()
	pts.append_array(back)
	poly(pts, Color(0.55, 0.42, 0.28))
	for i in 5:
		var t := 0.2 + i * 0.15
		var s := Vector2(-30 + t * 52, -10 - sin(t * PI * 0.9) * 10 - t * 26)
		draw_line(s + Vector2(0, 2 + t * 9), s - Vector2(0, 2 + t * 9), Color(0.36, 0.26, 0.16), 1.2)
	draw_line(Vector2(22, -36 + 11), Vector2(22, -36 - 11), Color(0.82, 0.8, 0.76), 4.0)
	draw_line(Vector2(-29, -12), Vector2(-33, -10), Color(0.82, 0.8, 0.76), 3.0)
