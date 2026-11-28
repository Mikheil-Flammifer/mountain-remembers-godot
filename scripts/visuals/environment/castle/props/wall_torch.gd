@tool
@icon("res://assets/icons/castle/wall_torch.svg")
class_name CastleWallTorch
extends CastleProp
## Iron wall bracket holding a burning pine torch. The flame flickers.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw_prop() -> void:
	glow(Vector2(0, -78), 120, Color(1.0, 0.6, 0.2))
	draw_rect(Rect2(-9, -22, 18, 22), Color(0.18, 0.17, 0.17))
	draw_circle(Vector2(0, -11), 2.5, Color(0.4, 0.38, 0.36))
	draw_line(Vector2(0, -16), Vector2(0, -40), Color(0.2, 0.19, 0.19), 4.0)
	draw_arc(Vector2(0, -44), 9, 0, PI, 10, Color(0.22, 0.2, 0.2), 3.0)
	poly(PackedVector2Array([Vector2(-5, -30), Vector2(5, -30), Vector2(8, -62), Vector2(-8, -62)]), Color(0.42, 0.28, 0.16))
	for i in 4:
		draw_line(Vector2(-7, -60 + i * 3), Vector2(7, -60 + i * 3), Color(0.25, 0.17, 0.1), 1.0)
	flame(Vector2(0, -60), 22, 42, _t)
