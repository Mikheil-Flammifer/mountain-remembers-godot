@tool
class_name SilentSheepdog
extends Node2D
## Non-colliding alpine sheepdog, separate from the story character Murana.
## Quiet idle breathing changes to a small wag after the optional E interaction.

@export var calm: bool = false

const FUR := Color("#a48a69")
const FUR_SHADOW := Color("#756a57")
const FUR_LIGHT := Color("#d2b995")
const FACE := Color("#4e4b40")
const SOIL := Color("#172727", 0.3)

var _time: float = 0.0
var _clock: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	_clock += delta
	if _clock >= 0.08:
		_clock = 0.0
		queue_redraw()


func soothe() -> void:
	calm = true
	queue_redraw()


func _draw() -> void:
	var breathing: float = sin(_time * 1.7) * 1.2
	draw_circle(Vector2(1, -2), 26.0, Color(SOIL, 0.38))
	# Hunched hindquarters and lowered tail.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-33, -18), Vector2(-39, -34), Vector2(-34, -48),
		Vector2(-24, -52), Vector2(-7, -50), Vector2(13, -44),
		Vector2(26, -32), Vector2(22, -11), Vector2(6, -7),
		Vector2(-15, -11)
	]), FUR_SHADOW)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-31, -33 + breathing), Vector2(-25, -50 + breathing),
		Vector2(-9, -55 + breathing), Vector2(12, -49 + breathing),
		Vector2(25, -35 + breathing), Vector2(16, -17),
		Vector2(-10, -19), Vector2(-28, -23)
	]), FUR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-19, -49 + breathing), Vector2(-8, -54 + breathing),
		Vector2(8, -49 + breathing), Vector2(16, -41 + breathing),
		Vector2(-12, -43 + breathing)
	]), Color(FUR_LIGHT, 0.45))
	# Rear legs sit close to the body while the dog waits in uncertainty.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-29, -24), Vector2(-17, -22),
		Vector2(-13, -8), Vector2(-18, 0), Vector2(-34, 0)
	]), FUR_SHADOW)
	draw_colored_polygon(PackedVector2Array([
		Vector2(7, -25), Vector2(17, -25),
		Vector2(23, -11), Vector2(24, 0), Vector2(14, 0),
		Vector2(9, -12)
	]), FUR)
	# Tail: low and still at first, gently raised when comforted.
	var wag: float = sin(_time * 3.1) * 5.0 if calm else sin(_time * 0.8) * 0.5
	draw_line(Vector2(-29, -39), Vector2(-43, -26 - wag), FUR_SHADOW, 8.0, true)
	draw_line(Vector2(-43, -26 - wag), Vector2(-49, -15 - wag), FUR, 5.0, true)
	# Broad guardian dog's head and lowered ears.
	draw_colored_polygon(PackedVector2Array([
		Vector2(13, -50 + breathing), Vector2(24, -62 + breathing),
		Vector2(37, -60 + breathing), Vector2(46, -49 + breathing),
		Vector2(45, -32 + breathing), Vector2(28, -29 + breathing),
		Vector2(17, -38 + breathing)
	]), FUR_LIGHT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(14, -57 + breathing), Vector2(24, -66 + breathing),
		Vector2(25, -50 + breathing), Vector2(19, -43 + breathing)
	]), FUR_SHADOW)
	draw_colored_polygon(PackedVector2Array([
		Vector2(39, -58 + breathing), Vector2(48, -64 + breathing),
		Vector2(47, -44 + breathing), Vector2(40, -41 + breathing)
	]), FUR_SHADOW)
	draw_colored_polygon(PackedVector2Array([
		Vector2(30, -49 + breathing), Vector2(48, -47 + breathing),
		Vector2(50, -34 + breathing), Vector2(37, -31 + breathing),
		Vector2(27, -40 + breathing)
	]), FACE)
	draw_circle(Vector2(34, -47 + breathing), 2.3, Color("#181e1d"))
	draw_circle(Vector2(35, -48 + breathing), 0.7, Color("#dcd6b5"))
	draw_circle(Vector2(50, -36 + breathing), 2.3, Color("#172121"))
	# Cream chest fur subtly responds to breathing.
	draw_colored_polygon(PackedVector2Array([
		Vector2(17, -37 + breathing), Vector2(26, -30 + breathing),
		Vector2(24, -22), Vector2(14, -18), Vector2(9, -25)
	]), Color(FUR_LIGHT, 0.78))
	if calm:
		draw_line(Vector2(42, -31 + breathing), Vector2(47, -30 + breathing), Color("#d8c2a0"), 1.1)
