@tool
class_name CastleProp
extends Node2D
## Base for every Khevsur castle interior prop. Origin is the bottom-centre of the
## prop (where it stands on the floor, table or wall). Change prop_seed for a
## differently textured copy of the same prop.

@export var prop_seed: int = 1:
	set(value):
		prop_seed = value
		queue_redraw()

var rng := RandomNumberGenerator.new()


func _draw() -> void:
	rng.seed = hash([prop_seed, get_script().resource_path])
	_draw_prop()


func _draw_prop() -> void:
	pass


func vary(c: Color, amount: float = 0.08) -> Color:
	var t := rng.randf_range(-amount, amount)
	return c.lightened(t) if t > 0.0 else c.darkened(-t)


func poly(points: PackedVector2Array, c: Color) -> void:
	draw_colored_polygon(points, c)


## Rough-cut stone block with lit top-left edge, shadowed bottom-right and pits.
func stone_block(r: Rect2, base: Color) -> void:
	var j := minf(r.size.x, r.size.y) * 0.08
	var pts := PackedVector2Array([
		r.position + Vector2(rng.randf_range(0, j), rng.randf_range(0, j)),
		Vector2(r.end.x - rng.randf_range(0, j), r.position.y + rng.randf_range(0, j)),
		r.end - Vector2(rng.randf_range(0, j), rng.randf_range(0, j)),
		Vector2(r.position.x + rng.randf_range(0, j), r.end.y - rng.randf_range(0, j)),
	])
	var c := vary(base, 0.12)
	poly(pts, c)
	draw_line(pts[0], pts[1], c.lightened(0.18), 2.0)
	draw_line(pts[0], pts[3], c.lightened(0.1), 1.5)
	draw_line(pts[1], pts[2], c.darkened(0.3), 2.0)
	draw_line(pts[3], pts[2], c.darkened(0.35), 2.5)
	for i in int(r.get_area() / 260.0):
		var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		draw_circle(p, rng.randf_range(0.6, 1.8), c.darkened(rng.randf_range(0.12, 0.3)))
	if rng.randf() < 0.3:
		var a := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y * 0.5)
		draw_polyline(PackedVector2Array([a, a + Vector2(rng.randf_range(-6, 6), 5), a + Vector2(rng.randf_range(-8, 8), 10)]), c.darkened(0.4), 1.0)


## Wooden plank with grain lines, a knot sometimes, and shaded edges.
func wood_plank(r: Rect2, base: Color, vertical: bool = false) -> void:
	var c := vary(base, 0.07)
	draw_rect(r, c)
	var lines := int((r.size.x if vertical else r.size.y) / 3.0)
	for i in lines:
		var t := (i + rng.randf()) / maxf(lines, 1)
		var col := c.darkened(rng.randf_range(0.08, 0.22))
		var pts := PackedVector2Array()
		for k in 7:
			var u := k / 6.0
			var wob := sin(u * 6.0 + i) * rng.randf_range(0.3, 1.2)
			if vertical:
				pts.append(Vector2(r.position.x + t * r.size.x + wob, r.position.y + u * r.size.y))
			else:
				pts.append(Vector2(r.position.x + u * r.size.x, r.position.y + t * r.size.y + wob))
		draw_polyline(pts, col, 0.8)
	if rng.randf() < 0.4:
		var kp := r.position + Vector2(rng.randf_range(0.2, 0.8) * r.size.x, rng.randf_range(0.2, 0.8) * r.size.y)
		draw_circle(kp, 3.0, c.darkened(0.35))
		draw_arc(kp, 5.0, 0, TAU, 12, c.darkened(0.2), 1.0)
	draw_line(r.position, Vector2(r.end.x, r.position.y), c.lightened(0.15), 1.5)
	draw_line(Vector2(r.position.x, r.end.y), r.end, c.darkened(0.4), 2.0)


func flame(base: Vector2, w: float, h: float, t: float) -> void:
	for layer in 3:
		var s := 1.0 - layer * 0.28
		var col: Color = [Color(0.85, 0.25, 0.05, 0.9), Color(1.0, 0.6, 0.1, 0.95), Color(1.0, 0.92, 0.55, 1.0)][layer]
		var sway := sin(t * 7.0 + layer) * w * 0.15
		var flick := 1.0 + sin(t * 11.0 + layer * 2.0) * 0.08
		poly(PackedVector2Array([
			base + Vector2(-w * 0.5 * s, 0),
			base + Vector2(-w * 0.45 * s, -h * 0.35 * s),
			base + Vector2(-w * 0.15 * s + sway * 0.5, -h * 0.6 * s * flick),
			base + Vector2(sway, -h * s * flick),
			base + Vector2(w * 0.2 * s + sway * 0.5, -h * 0.55 * s * flick),
			base + Vector2(w * 0.45 * s, -h * 0.3 * s),
			base + Vector2(w * 0.5 * s, 0),
		]), col)


func glow(center: Vector2, radius: float, c: Color) -> void:
	for i in 6:
		var k := 1.0 - i / 6.0
		draw_circle(center, radius * k, Color(c.r, c.g, c.b, 0.05 + 0.03 * i))
