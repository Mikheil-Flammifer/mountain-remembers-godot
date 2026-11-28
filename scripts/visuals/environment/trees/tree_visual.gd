@tool
class_name TreeVisual
extends Node2D
## Reusable, detailed procedural tree. Origin is the foot of the trunk.
## Pick a kind, a seed (each seed grows a different tree) and a height.

enum Kind { OAK, BEECH, BIRCH, PINE, SPRUCE, DEAD }

const LIGHT := Vector2(-0.6, -0.8)

@export var kind: Kind = Kind.OAK:
	set(value):
		kind = value
		queue_redraw()
@export var tree_seed: int = 1:
	set(value):
		tree_seed = value
		queue_redraw()
@export_range(60.0, 900.0) var height: float = 300.0:
	set(value):
		height = value
		queue_redraw()
@export var autumn: bool = false:
	set(value):
		autumn = value
		queue_redraw()

var _rng := RandomNumberGenerator.new()
var _tips: Array[Vector2] = []


func _draw() -> void:
	_rng.seed = hash([tree_seed, kind])
	_tips.clear()
	_draw_ground_shadow()
	match kind:
		Kind.SPRUCE:
			_draw_spruce()
		Kind.PINE:
			_draw_broadleaf(0.62, 0.035, 4, 0.35, 0.5)
		Kind.BIRCH:
			_draw_broadleaf(0.45, 0.035, 5, 0.42, 0.75)
		Kind.BEECH:
			_draw_broadleaf(0.3, 0.06, 5, 0.7, 0.74)
		Kind.DEAD:
			_draw_broadleaf(0.35, 0.06, 6, 0.75, 0.74)
		_:
			_draw_broadleaf(0.3, 0.085, 5, 1.05, 0.72)


# --- broadleaf and pine: trunk + recursive branches + leaf clusters ---

func _draw_broadleaf(trunk_frac: float, width_frac: float, depth: int, spread: float, shrink: float) -> void:
	var trunk_h := height * trunk_frac
	var w := height * width_frac
	_draw_roots(w)
	var top := Vector2(_rng.randf_range(-0.04, 0.04) * height, -trunk_h)
	_draw_limb(Vector2.ZERO, top, w, w * 0.7, true)
	var branch_len := (height - trunk_h) * (0.5 if kind == Kind.PINE else 0.4)
	var count := 3 if kind != Kind.BIRCH else 4
	for i in count:
		var a := -PI / 2.0 + lerpf(-spread, spread, (i + 0.5) / count) + _rng.randf_range(-0.15, 0.15)
		_branch(top, a, branch_len * _rng.randf_range(0.8, 1.05), w * 0.6, depth, spread, shrink)
	if kind == Kind.PINE:
		# a few bare lower stubs along the tall trunk
		for i in 4:
			var y := -trunk_h * _rng.randf_range(0.35, 0.95)
			var side := -1.0 if i % 2 == 0 else 1.0
			_draw_limb(Vector2(0, y), Vector2(0, y) + Vector2(side * height * 0.06, -height * 0.02), w * 0.18, w * 0.05, false)
	if kind != Kind.DEAD:
		_draw_foliage()


func _branch(from: Vector2, angle: float, length: float, w: float, depth: int, spread: float, shrink: float) -> void:
	angle = clampf(angle, -PI / 2.0 - 1.0, -PI / 2.0 + 1.0)  # keep crowns rounded, not umbrella-flat
	var bend := _rng.randf_range(-0.12, 0.12)
	var to := from + Vector2.from_angle(angle + bend) * length
	if kind == Kind.BIRCH and depth <= 2:
		to.y += length * 0.25  # drooping twigs
	_draw_limb(from, to, w, w * 0.62, depth > 2)
	if depth <= 0:
		_tips.append(to)
		return
	if depth <= 3:
		_tips.append(from.lerp(to, 0.6))
	var children := 2 if _rng.randf() < 0.6 else 3
	for i in children:
		var a := angle + lerpf(-spread, spread, (i + 0.5) / children) * 0.7 + _rng.randf_range(-0.2, 0.2)
		_branch(to, a, length * _rng.randf_range(shrink - 0.08, shrink + 0.05), w * 0.62, depth - 1, spread, shrink)


func _draw_roots(w: float) -> void:
	var bark := _bark_color()
	for side: float in [-1.0, 1.0]:
		var pts := PackedVector2Array([
			Vector2(side * w * 0.3, -w * 0.9), Vector2(side * w * 1.1, 0), Vector2(side * w * 0.2, 2)])
		draw_colored_polygon(pts, bark.darkened(0.15))


func _draw_limb(a: Vector2, b: Vector2, wa: float, wb: float, textured: bool) -> void:
	var dir := (b - a).normalized()
	var n := Vector2(-dir.y, dir.x)
	var bark := _bark_color()
	var pts := PackedVector2Array([a + n * wa * 0.5, b + n * wb * 0.5, b - n * wb * 0.5, a - n * wa * 0.5])
	draw_colored_polygon(pts, bark)
	# shaded side (away from light) and lit edge
	var lit_side := 1.0 if n.dot(LIGHT) > 0.0 else -1.0
	draw_colored_polygon(PackedVector2Array([a - n * lit_side * wa * 0.5, b - n * lit_side * wb * 0.5, b - n * lit_side * wb * 0.1, a - n * lit_side * wa * 0.1]), bark.darkened(0.3))
	draw_line(a + n * lit_side * wa * 0.4, b + n * lit_side * wb * 0.4, bark.lightened(0.25), maxf(1.0, wb * 0.12))
	if textured:
		_bark_texture(a, b, wa, wb, n, dir)


func _bark_texture(a: Vector2, b: Vector2, wa: float, wb: float, n: Vector2, dir: Vector2) -> void:
	var len := a.distance_to(b)
	var bark := _bark_color()
	var marks := int(len * maxf(wa, 4.0) / 40.0)
	for i in marks:
		var t := _rng.randf()
		var half := lerpf(wa, wb, t) * 0.45
		var p := a.lerp(b, t) + n * _rng.randf_range(-half, half)
		if kind == Kind.BIRCH:
			# dark horizontal lenticels on white bark
			var dash := n * _rng.randf_range(2.0, half * 1.1)
			draw_line(p - dash * 0.5, p + dash * 0.5, Color(0.12, 0.11, 0.1, 0.85), _rng.randf_range(1.0, 2.5))
		elif kind == Kind.BEECH:
			draw_line(p, p + n * _rng.randf_range(2, 6), bark.lightened(0.18), 1.0)
		else:
			# furrowed bark: short vertical cracks, dark with a light lip
			var crack := dir * _rng.randf_range(5.0, 16.0)
			draw_line(p, p + crack, bark.darkened(0.45), _rng.randf_range(1.0, 2.2))
			draw_line(p + n, p + n + crack * 0.8, bark.lightened(0.15), 1.0)
	if kind == Kind.PINE and wa > 6.0:
		# orange plates on the upper trunk
		for i in marks / 3:
			var t := _rng.randf_range(0.4, 1.0)
			var p := a.lerp(b, t) + n * _rng.randf_range(-wa * 0.35, wa * 0.35)
			draw_rect(Rect2(p, Vector2(_rng.randf_range(3, 7), _rng.randf_range(4, 9))), Color(0.78, 0.45, 0.25, 0.8))


func _draw_foliage() -> void:
	var base_r := height * (0.07 if kind == Kind.PINE else 0.085)
	if kind == Kind.BIRCH:
		base_r = height * 0.06
	var palette := _leaf_palette()
	var center := Vector2.ZERO
	for t in _tips:
		center += t
	center /= maxf(1.0, _tips.size())
	# dark inner mass first, so gaps between leaves read as depth, not sky
	for tip in _tips:
		for i in 5:
			var off := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * base_r * 0.6
			if kind == Kind.PINE:
				off.y *= 0.45
			_blob(tip + off - LIGHT * base_r * 0.15, base_r * _rng.randf_range(0.5, 0.75), palette[0].darkened(0.35))
	var spread := 1.0
	for layer in 4:
		for tip in _tips:
			var leaves := 26 if kind != Kind.PINE else 34
			for i in leaves:
				var off := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * base_r * spread
				if kind == Kind.PINE:
					off.y *= 0.45  # flat cloud-like pine crowns
				off += LIGHT * base_r * 0.18 * layer
				var p := tip + off
				var facing := clampf((p - center).normalized().dot(LIGHT) * 0.5 + 0.5, 0.0, 1.0)
				var col: Color = palette[layer].lerp(palette[mini(layer + 1, 3)], facing * 0.5)
				col = col.lightened(_rng.randf_range(-0.08, 0.08))
				_leaf(p, base_r * _rng.randf_range(0.11, 0.2), _rng.randf() * TAU, col)
		spread *= 0.82


func _leaf(p: Vector2, r: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var long := r * (2.2 if kind == Kind.PINE else 1.0)
	var wide := r * (0.28 if kind == Kind.PINE else 0.6)
	for k in 6:
		var a := TAU * k / 6.0
		pts.append(p + Vector2(cos(a) * long, sin(a) * wide).rotated(rot))
	draw_colored_polygon(pts, col)
	if r > 3.0 and r < 7.0 and kind != Kind.PINE:
		draw_line(p - Vector2(long * 0.7, 0).rotated(rot), p + Vector2(long * 0.7, 0).rotated(rot), col.darkened(0.25), 1.0)


func _blob(p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * k / 10.0
		pts.append(p + Vector2(cos(a), sin(a) * (0.5 if kind == Kind.PINE else 0.85)) * r * _rng.randf_range(0.8, 1.1))
	draw_colored_polygon(pts, col)


# --- spruce: straight trunk with drooping needle tiers ---

func _draw_spruce() -> void:
	var w := height * 0.05
	_draw_roots(w)
	_draw_limb(Vector2.ZERO, Vector2(0, -height), w, 1.0, true)
	var tiers := 16
	var max_w := height * 0.24
	var greens := [Color(0.06, 0.15, 0.1), Color(0.1, 0.22, 0.14), Color(0.16, 0.31, 0.19), Color(0.3, 0.45, 0.28)]
	for i in tiers:
		var t := float(i) / tiers
		var y := -height * lerpf(0.12, 0.97, t)
		var half := max_w * pow(1.0 - t, 0.95) * _rng.randf_range(0.85, 1.1)
		var tier_h := height * 0.07
		for side: float in [-1.0, 1.0]:
			var tip := Vector2(side * half, y + half * 0.35)
			_draw_limb(Vector2(0, y), tip, maxf(2.0, w * 0.25 * (1.0 - t)), 1.0, false)
			for layer in 4:
				var n := int(60 * (1.0 - t * 0.6))
				for k in n:
					var u := _rng.randf()
					var along := Vector2(0, y).lerp(tip, u)
					var p := along + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-tier_h * 0.5, tier_h * 0.25) * (1.0 - u * 0.5))
					p.y -= layer * 2.0
					var lit: float = 0.3 if side > 0.0 else 0.0
					var col: Color = greens[layer].lightened(lit * 0.3 + _rng.randf_range(-0.05, 0.06))
					var ang: float = (PI * 0.5 - side * 0.9) + _rng.randf_range(-0.5, 0.5)
					var nl := _rng.randf_range(4.0, 9.0) * (1.0 - t * 0.4)
					draw_line(p, p + Vector2.from_angle(ang) * nl, col, 1.6)
		# hanging cones on upper tiers
		if t > 0.55 and _rng.randf() < 0.5:
			var c := Vector2(_rng.randf_range(-half, half) * 0.6, y + tier_h * 0.3)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2, 0), c + Vector2(2, 0), c + Vector2(1.5, 9), c + Vector2(-1.5, 9)]), Color(0.42, 0.24, 0.12))
	# leader at the top
	draw_line(Vector2(0, -height * 0.97), Vector2(0, -height * 1.03), greens[2], 2.0)


# --- colours ---

func _bark_color() -> Color:
	match kind:
		Kind.BIRCH: return Color(0.9, 0.88, 0.82)
		Kind.BEECH: return Color(0.52, 0.53, 0.5)
		Kind.PINE: return Color(0.42, 0.26, 0.17)
		Kind.SPRUCE: return Color(0.3, 0.2, 0.14)
		Kind.DEAD: return Color(0.45, 0.42, 0.38)
	return Color(0.33, 0.25, 0.18)


func _leaf_palette() -> Array:
	if autumn and kind in [Kind.OAK, Kind.BEECH, Kind.BIRCH]:
		if kind == Kind.BIRCH:
			return [Color(0.55, 0.42, 0.08), Color(0.75, 0.6, 0.12), Color(0.9, 0.75, 0.2), Color(1.0, 0.9, 0.45)]
		return [Color(0.4, 0.15, 0.06), Color(0.62, 0.27, 0.08), Color(0.82, 0.45, 0.12), Color(0.95, 0.7, 0.3)]
	match kind:
		Kind.BIRCH: return [Color(0.2, 0.33, 0.12), Color(0.35, 0.5, 0.18), Color(0.5, 0.65, 0.25), Color(0.7, 0.8, 0.4)]
		Kind.BEECH: return [Color(0.14, 0.27, 0.1), Color(0.25, 0.42, 0.15), Color(0.38, 0.56, 0.22), Color(0.58, 0.72, 0.35)]
		Kind.PINE: return [Color(0.05, 0.14, 0.11), Color(0.1, 0.24, 0.17), Color(0.17, 0.33, 0.22), Color(0.32, 0.46, 0.3)]
	return [Color(0.1, 0.2, 0.08), Color(0.18, 0.32, 0.12), Color(0.29, 0.45, 0.17), Color(0.48, 0.6, 0.28)]


func _draw_ground_shadow() -> void:
	var pts := PackedVector2Array()
	var rx := height * (0.3 if kind in [Kind.OAK, Kind.BEECH] else 0.18)
	for k in 16:
		var a := TAU * k / 16.0
		pts.append(Vector2(cos(a) * rx, sin(a) * rx * 0.12))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.25))
