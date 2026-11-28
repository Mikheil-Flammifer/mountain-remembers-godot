@tool
@icon("res://assets/icons/castle/hearth.svg")
class_name CastleHearth
extends CastleProp
## Stone hearth with burning logs and a black cauldron on a chain.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw_prop() -> void:
	glow(Vector2(0, -60), 220, Color(1.0, 0.5, 0.15))
	for i in 6:
		stone_block(Rect2(-120, -40 - i * 36, 40, 34), Color(0.5, 0.45, 0.38))
		stone_block(Rect2(80, -40 - i * 36, 40, 34), Color(0.5, 0.45, 0.38))
	for i in 5:
		stone_block(Rect2(-120 + i * 48, -282, 46, 40), Color(0.52, 0.47, 0.4))
	draw_rect(Rect2(-80, -242, 160, 202), Color(0.08, 0.05, 0.04))
	draw_rect(Rect2(-80, -242, 160, 60), Color(0.03, 0.02, 0.02))
	draw_rect(Rect2(-130, -40, 260, 40), Color(0.34, 0.3, 0.26))
	stone_block(Rect2(-130, -40, 260, 16), Color(0.46, 0.42, 0.36))
	draw_line(Vector2(0, -242), Vector2(0, -150), Color(0.15, 0.14, 0.14), 3.0)
	flame(Vector2(-25, -46), 60, 80, _t)
	flame(Vector2(25, -46), 50, 70, _t + 1.3)
	poly(PackedVector2Array([Vector2(-40, -150), Vector2(40, -150), Vector2(34, -110), Vector2(18, -98), Vector2(-18, -98), Vector2(-34, -110)]), Color(0.1, 0.09, 0.09))
	draw_arc(Vector2(0, -150), 40, PI, TAU, 16, Color(0.2, 0.19, 0.19), 3.0)
	draw_line(Vector2(-36, -140), Vector2(-20, -104), Color(0.3, 0.25, 0.2, 0.6), 2.0)
	draw_rect(Rect2(-42, -154, 84, 6), Color(0.18, 0.17, 0.17))
	for i in 3:
		var y := -42.0 - i * 9.0
		draw_line(Vector2(-60, y), Vector2(60, y + (6 if i % 2 == 0 else -6)), Color(0.32, 0.2, 0.12), 9.0)
		draw_circle(Vector2(60, y + (6 if i % 2 == 0 else -6)), 4, Color(0.55, 0.4, 0.25))
	for i in 12:
		draw_circle(Vector2(rng.randf_range(-70, 70), rng.randf_range(-48, -42)), rng.randf_range(1.5, 3), Color(1.0, 0.45, 0.1))
