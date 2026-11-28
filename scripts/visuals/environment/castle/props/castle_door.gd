@tool
@icon("res://assets/icons/castle/castle_door.svg")
class_name CastleDoor
extends CastleProp
## Heavy plank door with iron bands inside an arched stone frame. Set open to show it ajar.

@export var open := true:
	set(value):
		open = value
		queue_redraw()


func _draw_prop() -> void:
	for i in 7:
		stone_block(Rect2(-95, -36 - i * 36, 30, 34), Color(0.5, 0.45, 0.38))
		stone_block(Rect2(65, -36 - i * 36, 30, 34), Color(0.5, 0.45, 0.38))
	for i in 9:
		var a := PI + PI * i / 8.0
		var p := Vector2(0, -252) + Vector2.RIGHT.rotated(a) * 80
		stone_block(Rect2(p - Vector2(15, 15), Vector2(30, 30)), Color(0.52, 0.47, 0.4))
	draw_rect(Rect2(-65, -252, 130, 252), Color(0.06, 0.05, 0.05))
	draw_circle(Vector2(0, -252), 65, Color(0.06, 0.05, 0.05))
	draw_rect(Rect2(-65, -120, 130, 120), Color(0.12, 0.14, 0.22, 0.6))
	var w := 60.0 if open else 130.0
	for i in 5:
		wood_plank(Rect2(-65 + i * w / 5.0, -250, w / 5.0, 250), Color(0.4, 0.27, 0.16), true)
	for y in [-210.0, -125.0, -40.0]:
		draw_rect(Rect2(-65, y, w, 9), Color(0.17, 0.16, 0.16))
		for k in 4:
			draw_circle(Vector2(-60 + k * w / 4.0 + 6, y + 4.5), 2.2, Color(0.4, 0.38, 0.36))
	draw_arc(Vector2(-65 + w - 12, -125), 7, 0, TAU, 12, Color(0.2, 0.19, 0.19), 2.5)
