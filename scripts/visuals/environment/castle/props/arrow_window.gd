@tool
@icon("res://assets/icons/castle/arrow_window.svg")
class_name CastleArrowWindow
extends CastleProp
## Narrow tower loophole with a deep stone reveal and the night sky outside.


func _draw_prop() -> void:
	stone_block(Rect2(-34, -150, 68, 18), Color(0.5, 0.46, 0.4))
	stone_block(Rect2(-34, -10, 68, 14), Color(0.5, 0.46, 0.4))
	for i in 5:
		stone_block(Rect2(-34, -132 + i * 24, 18, 22), Color(0.48, 0.44, 0.38))
		stone_block(Rect2(16, -132 + i * 24, 18, 22), Color(0.48, 0.44, 0.38))
	draw_rect(Rect2(-16, -132, 32, 122), Color(0.12, 0.1, 0.09))
	poly(PackedVector2Array([Vector2(-8, -128), Vector2(8, -128), Vector2(8, -14), Vector2(-8, -14)]), Color(0.1, 0.16, 0.3))
	for i in 5:
		draw_circle(Vector2(rng.randf_range(-6, 6), rng.randf_range(-124, -40)), rng.randf_range(0.6, 1.3), Color(1, 1, 0.85, 0.9))
	poly(PackedVector2Array([Vector2(-8, -40), Vector2(-2, -52), Vector2(5, -44), Vector2(8, -50), Vector2(8, -14), Vector2(-8, -14)]), Color(0.06, 0.08, 0.14))
	poly(PackedVector2Array([Vector2(-16, -132), Vector2(-8, -128), Vector2(-8, -14), Vector2(-16, -10)]), Color(0.22, 0.19, 0.16))
