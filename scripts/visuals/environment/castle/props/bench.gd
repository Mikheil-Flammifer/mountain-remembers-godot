@tool
@icon("res://assets/icons/castle/bench.svg")
class_name CastleBench
extends CastleProp
## Low wooden bench with a back rail. Guests sit on it behind the feast table.

@export var length := 200.0:
	set(value):
		length = value
		queue_redraw()


func _draw_prop() -> void:
	var l := length * 0.5
	for s in [-1.0, 1.0]:
		wood_plank(Rect2(s * (l - 12) - 6, -150, 12, 150), Color(0.34, 0.21, 0.12), true)
		draw_circle(Vector2(s * (l - 12), -154), 6, Color(0.45, 0.3, 0.17))
	wood_plank(Rect2(-l, -150, length, 16), Color(0.42, 0.27, 0.15))
	wood_plank(Rect2(-l, -112, length, 10), Color(0.4, 0.26, 0.14))
	var n := int(length / 30.0)
	for i in n:
		var x := -l + 18 + (length - 36) * i / maxf(n - 1, 1)
		draw_line(Vector2(x, -134), Vector2(x, -112), Color(0.3, 0.19, 0.1), 4.0)
	wood_plank(Rect2(-l - 6, -66, length + 12, 14), Color(0.46, 0.3, 0.17))
