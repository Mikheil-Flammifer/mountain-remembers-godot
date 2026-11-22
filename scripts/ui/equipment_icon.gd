extends Control

## Drawn HUD equipment icon: stone, shield or sword. No external textures.

var icon_type: String = "stone"
var key_text: String = "R"
var caption: String = "STONE"
var active: bool = false
var count: int = -1
var level: int = 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_state(next_active: bool) -> void:
	active = next_active
	queue_redraw()


func set_count(next_count: int) -> void:
	count = next_count
	queue_redraw()


func set_level(next_level: int) -> void:
	level = clampi(next_level, 1, 5)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(37.0, 37.0)
	var rim: Color = Color("#85724f")
	if active:
		rim = Color("#d7bd79")

	# Double-ring frame with a restrained medieval-metal look.
	draw_circle(center, 35.0, Color(0.035, 0.045, 0.050, 0.92))
	draw_arc(center, 34.0, 0.0, TAU, 48, Color("#3d3529"), 5.0)
	draw_arc(center, 31.0, 0.0, TAU, 48, rim, 2.0)
	draw_circle(center, 26.0, Color("#11181a"))

	match icon_type:
		"shield":
			_draw_shield(center)
		"sword":
			_draw_sword(center)
		_:
			_draw_stone(center)

	_draw_key_badge()
	_draw_caption()
	if count >= 0:
		_draw_count_badge()
	_draw_level_badge()


func _draw_stone(center: Vector2) -> void:
	var stone := PackedVector2Array([
		center + Vector2(-14,-4), center + Vector2(-7,-17),
		center + Vector2(8,-19), center + Vector2(17,-7),
		center + Vector2(14,10), center + Vector2(1,17),
		center + Vector2(-13,11)
	])
	draw_colored_polygon(stone, Color("#6f8178"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-7,-14), center + Vector2(8,-16),
		center + Vector2(3,-3), center + Vector2(-10,0)
	]), Color("#94a097"))
	draw_line(center + Vector2(-9,4), center + Vector2(9,9), Color("#475650"), 2.0)


func _draw_shield(center: Vector2) -> void:
	var shield := PackedVector2Array([
		center + Vector2(0,-21), center + Vector2(15,-15),
		center + Vector2(18,-2), center + Vector2(13,13),
		center + Vector2(0,22), center + Vector2(-13,13),
		center + Vector2(-18,-2), center + Vector2(-15,-15)
	])
	draw_colored_polygon(shield, Color("#4e4639"))
	draw_polyline(shield, Color("#a48b5b"), 3.0, true)
	draw_line(center + Vector2(0,-17), center + Vector2(0,17), Color("#766746"), 2.0)
	draw_circle(center, 6.0, Color("#b49b68"))


func _draw_sword(center: Vector2) -> void:
	var base := center + Vector2(-12,15)
	var tip := center + Vector2(15,-19)
	draw_line(base, tip, Color("#d6d6cd"), 6.0)
	draw_line(base + Vector2(2,-2), tip, Color("#f0e8cf"), 2.0)
	draw_line(center + Vector2(-17,8), center + Vector2(-4,19), Color("#a48b5b"), 5.0)
	draw_line(center + Vector2(-15,17), center + Vector2(-7,25), Color("#6a4931"), 6.0)
	draw_circle(center + Vector2(-5,25), 3.0, Color("#b79c67"))


func _draw_key_badge() -> void:
	draw_circle(Vector2(12,12), 10.0, Color("#211d18"))
	draw_arc(Vector2(12,12), 9.0, 0.0, TAU, 24, Color("#8f7b56"), 1.5)
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(8,16), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ead8aa"))


func _draw_caption() -> void:
	var font: Font = get_theme_default_font()
	draw_string(
		font,
		Vector2(0,87),
		caption,
		HORIZONTAL_ALIGNMENT_CENTER,
		74.0,
		10,
		Color("#d3c5a6")
	)


func _draw_count_badge() -> void:
	var badge_center := Vector2(62,61)
	draw_circle(badge_center, 11.0, Color("#15191a"))
	draw_arc(badge_center, 10.0, 0.0, TAU, 24, Color("#a58d60"), 1.5)
	var text: String = str(count)
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(55,66), text, HORIZONTAL_ALIGNMENT_CENTER, 14.0, 12, Color("#f1dfb1"))


func _draw_level_badge() -> void:
	var center := Vector2(62, 13)
	draw_circle(center, 10.0, Color("#171b1c"))
	draw_arc(center, 9.0, 0.0, TAU, 24, Color("#8d7750"), 1.5)
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(54,17), "L%d" % level, HORIZONTAL_ALIGNMENT_CENTER, 16.0, 9, Color("#e5d3a5"))
