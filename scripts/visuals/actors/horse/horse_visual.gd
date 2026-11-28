class_name HorseVisual
extends Node2D
## A detailed, code-drawn Khevsur mountain horse with idle, walk and gallop
## animation. Origin is between the hooves on the ground; the horse faces +x.
## Gameplay code only calls update_gait(); everything here is presentation.

enum Gait { IDLE, WALK, GALLOP }

const SHOULDER := Vector2(28.0, -66.0)
const HIP := Vector2(-30.0, -68.0)
const UPPER := 27.0
const LOWER := 24.0
const PASTERN := 11.0
## Where a rider's hips sit, relative to the horse origin, at rest.
const SEAT := Vector2(-4.0, -90.0)

const COAT := Color("#6e3f20")
const COAT_SHADE := Color("#4b2913")
const COAT_LIGHT := Color("#93592f")
const COAT_FAR := Color("#3f2311")
const POINTS := Color("#1d1410")
const POINTS_FAR := Color("#120c09")
const HOOF := Color("#3a3029")
const MANE := Color("#17100c")
const BLAZE := Color("#efe6d6")
const LEATHER := Color("#3b2416")
const BRASS := Color("#c9a24f")
const BLANKET := Color("#8e1f22")
const BLANKET_DARK := Color("#2a1a22")
const BLANKET_CROSS := Color("#e7d6a9")

var gait: Gait = Gait.IDLE
var speed_ratio: float = 0.0
var facing: float = 1.0
var airborne: bool = false
## Normalised position (0..1) inside the current stride cycle.
var cycle: float = 0.0
## Rider seat including the body's bob and pitch this frame.
var seat_offset: Vector2 = SEAT
var saddled: bool = true

var _time: float = 0.0
var _bob: float = 0.0
var _pitch: float = 0.0
var _head_nod: float = 0.0
var _tail_lift: float = 0.0
var _ear_flick: float = 0.0
var _next_flick: float = 2.5
var _legs: Dictionary = {}
var _dust: Array = []


func _ready() -> void:
	_solve_legs()


func update_gait(ratio: float, direction: float, in_air: bool, delta: float) -> void:
	speed_ratio = clampf(ratio, 0.0, 1.3)
	airborne = in_air
	if not is_zero_approx(direction):
		facing = signf(direction)
	scale = Vector2(facing, 1.0)
	if speed_ratio < 0.05:
		gait = Gait.IDLE
	elif speed_ratio < 0.55:
		gait = Gait.WALK
	else:
		gait = Gait.GALLOP
	_time += delta
	var stride_hz: float = 0.0
	match gait:
		Gait.WALK:
			stride_hz = lerpf(0.9, 1.6, speed_ratio / 0.55)
		Gait.GALLOP:
			stride_hz = lerpf(2.1, 2.7, clampf((speed_ratio - 0.55) / 0.45, 0.0, 1.0))
	if not airborne:
		cycle = fposmod(cycle + stride_hz * delta, 1.0)
	var target_bob := 0.0
	var target_pitch := 0.0
	var target_nod := 0.0
	var target_tail := 0.0
	match gait:
		Gait.IDLE:
			# Slow breathing and the odd head dip.
			target_bob = sin(_time * 1.6) * 0.8
			target_nod = sin(_time * 0.7) * 0.05
		Gait.WALK:
			target_bob = -absf(sin(cycle * TAU * 2.0)) * 2.0
			target_nod = sin(cycle * TAU * 2.0) * 0.07
			target_tail = 0.15
		Gait.GALLOP:
			# Rocking-horse motion: fore and hind ends rise in turn.
			target_bob = -4.0 - sin(cycle * TAU) * 5.0
			target_pitch = sin(cycle * TAU + 0.9) * 0.07
			target_nod = sin(cycle * TAU + 2.2) * 0.16 - 0.12
			target_tail = 0.85
	if airborne:
		target_pitch = -0.08
		target_nod = -0.2
		target_tail = 1.0
	var k := clampf(delta * 12.0, 0.0, 1.0)
	_bob = lerpf(_bob, target_bob, k)
	_pitch = lerpf(_pitch, target_pitch, k)
	_head_nod = lerpf(_head_nod, target_nod, k)
	_tail_lift = lerpf(_tail_lift, target_tail, clampf(delta * 4.0, 0.0, 1.0))
	_next_flick -= delta
	if _next_flick <= 0.0:
		_ear_flick = 1.0
		_next_flick = randf_range(1.8, 4.5)
	_ear_flick = maxf(0.0, _ear_flick - delta * 3.0)
	seat_offset = Vector2(SEAT.x * facing, SEAT.y + _bob + SEAT.x * _pitch)
	_solve_legs()
	_update_dust(delta)
	queue_redraw()


## Name of the current gait, handy for tests and debugging.
func gait_name() -> StringName:
	return [&"idle", &"walk", &"gallop"][gait]


func leg_angles(leg: StringName) -> Vector2:
	return _legs.get(leg, {}).get("angles", Vector2.ZERO)


func _solve_legs() -> void:
	# Phase offsets per leg: rotary-free transverse gallop, 4-beat walk.
	var offsets := {
		&"hind_far": 0.0, &"hind_near": 0.1, &"fore_far": 0.36, &"fore_near": 0.46,
	}
	if gait == Gait.WALK:
		offsets = {&"hind_far": 0.0, &"fore_far": 0.25, &"hind_near": 0.5, &"fore_near": 0.75}
	for leg in offsets:
		var front: bool = String(leg).begins_with("fore")
		var p: float = fposmod(cycle + float(offsets[leg]), 1.0)
		var upper := 0.0
		var bend := 0.0
		if gait == Gait.IDLE:
			upper = 0.04 if front else -0.06
			if leg == &"hind_near":
				# Resting one hind hoof, as horses do.
				upper = -0.02
				bend = 0.35
		elif airborne:
			upper = 0.6 if front else -0.55
			bend = 1.3
		else:
			var stance: float = 0.42 if gait == Gait.GALLOP else 0.62
			var reach: float = 0.62 if gait == Gait.GALLOP else 0.3
			var fold: float = 1.55 if gait == Gait.GALLOP else 0.8
			if p < stance:
				var s := p / stance
				upper = lerpf(reach, -reach * 0.95, s)
				bend = 0.05
			else:
				var s := (p - stance) / (1.0 - stance)
				upper = lerpf(-reach * 0.95, reach, smoothstep(0.0, 1.0, s))
				bend = sin(s * PI) * fold
		# Knees fold backward on the forelegs, hocks fold forward on the hind.
		var lower := upper + (-bend if front else bend * 0.85)
		var pastern := lower + (bend * 0.5 if front else -bend * 0.35)
		var top: Vector2 = SHOULDER if front else HIP
		var a := top + _dir(upper) * UPPER
		var b := a + _dir(lower) * LOWER
		var c := b + _dir(pastern) * PASTERN
		_legs[leg] = {"top": top, "knee": a, "fetlock": b, "hoof": c, "angles": Vector2(upper, lower), "front": front, "phase": p}


func _dir(angle: float) -> Vector2:
	return Vector2(sin(angle), cos(angle))


func _update_dust(delta: float) -> void:
	if gait == Gait.GALLOP and not airborne:
		for leg in _legs:
			var p: float = _legs[leg].phase
			if p < 0.05 and randf() < 0.5:
				_dust.append({"pos": Vector2(_legs[leg].hoof.x, -2.0), "age": 0.0, "size": randf_range(3.0, 6.0)})
	for puff in _dust:
		puff.age += delta
		puff.pos += Vector2(-60.0, -14.0) * delta
	_dust = _dust.filter(func(puff): return puff.age < 0.6)


func _body_xf() -> Transform2D:
	# Body pivots around the middle of the barrel.
	var pivot := Vector2(0.0, -76.0)
	return Transform2D(0.0, Vector2(0.0, _bob) + pivot) * Transform2D(_pitch, Vector2.ZERO) * Transform2D(0.0, -pivot)


func _draw() -> void:
	for puff in _dust:
		var t: float = puff.age / 0.6
		draw_circle(puff.pos, puff.size * (1.0 + t * 1.6), Color(0.62, 0.55, 0.45, 0.35 * (1.0 - t)))
	# Ground shadow shrinks when the horse is off the ground.
	var shadow_scale := 0.75 if airborne else 1.0
	_draw_ellipse(Vector2(0, -1), Vector2(58, 5) * shadow_scale, Color(0, 0, 0, 0.22))
	var xf := _body_xf()
	draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_leg(&"hind_far", xf, true)
	_draw_leg(&"fore_far", xf, true)
	draw_set_transform_matrix(xf)
	_draw_tail()
	_draw_body()
	_draw_neck_and_head()
	if saddled:
		_draw_tack()
	draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_leg(&"hind_near", xf, false)
	_draw_leg(&"fore_near", xf, false)


func _draw_leg(leg: StringName, xf: Transform2D, far: bool) -> void:
	var data: Dictionary = _legs.get(leg, {})
	if data.is_empty():
		return
	var top: Vector2 = xf * data.top
	var knee: Vector2 = xf * data.knee
	var fet: Vector2 = xf * data.fetlock
	var hoof: Vector2 = xf * data.hoof
	var front: bool = data.front
	var coat := COAT_FAR if far else COAT
	var dark := POINTS_FAR if far else POINTS
	# Muscled forearm / gaskin tapering into the joint.
	var upper_w := 15.0 if front else 18.0
	_draw_limb(top + Vector2(0, -6), knee, upper_w, 8.0, coat)
	if not far:
		draw_line(top + Vector2(-2, 0), knee + Vector2(-1, 0), COAT_LIGHT.darkened(0.1), 2.0)
	# Bay horses have black lower legs.
	_draw_limb(knee, fet, 7.5, 5.5, dark)
	draw_circle(knee, 4.2, dark)
	draw_circle(fet, 3.6, dark)
	# Near hind leg wears a white sock.
	var pastern_color := BLAZE if (leg == &"hind_near") else dark
	_draw_limb(fet, hoof, 5.0, 4.6, pastern_color)
	# Feathering of hair at the fetlock.
	draw_polyline(PackedVector2Array([fet + Vector2(-3, 1), fet + Vector2(-6, 5), fet + Vector2(-3, 4)]), dark, 1.2)
	var along := (hoof - fet).normalized()
	var side := Vector2(along.y, -along.x)
	var hoof_poly := PackedVector2Array([
		hoof - side * 4.6, hoof + side * 4.6,
		hoof + side * 6.2 + along * 6.0, hoof - side * 5.0 + along * 6.0,
	])
	draw_colored_polygon(hoof_poly, HOOF.darkened(0.3) if far else HOOF)
	draw_line(hoof_poly[2], hoof_poly[3], Color("#8a8a86"), 1.3)  # iron shoe


func _draw_limb(a: Vector2, b: Vector2, wa: float, wb: float, color: Color) -> void:
	var along := (b - a).normalized()
	var side := Vector2(along.y, -along.x)
	draw_colored_polygon(PackedVector2Array([
		a + side * wa * 0.5, b + side * wb * 0.5, b - side * wb * 0.5, a - side * wa * 0.5,
	]), color)


func _draw_body() -> void:
	var barrel := PackedVector2Array([
		Vector2(46, -86), Vector2(40, -96), Vector2(24, -98), Vector2(6, -92), Vector2(-14, -92),
		Vector2(-32, -97), Vector2(-46, -93), Vector2(-54, -82), Vector2(-54, -68), Vector2(-46, -58),
		Vector2(-34, -55), Vector2(-14, -52), Vector2(8, -51), Vector2(26, -54), Vector2(40, -60),
		Vector2(50, -72),
	])
	draw_colored_polygon(barrel, COAT)
	# Belly shading and the darker flank under the croup.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-46, -60), Vector2(-14, -55), Vector2(8, -54), Vector2(26, -57), Vector2(40, -62),
		Vector2(26, -54), Vector2(8, -51), Vector2(-14, -52), Vector2(-34, -55),
	]), COAT_SHADE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-54, -82), Vector2(-54, -68), Vector2(-46, -58), Vector2(-40, -66), Vector2(-42, -80),
	]), COAT_SHADE)
	# Sheen along the back and the round of the hindquarter and shoulder.
	draw_polyline(PackedVector2Array([Vector2(36, -93), Vector2(22, -95), Vector2(4, -89), Vector2(-14, -89), Vector2(-30, -93)]), COAT_LIGHT, 2.5)
	draw_arc(Vector2(-36, -76), 13.0, -2.6, -0.6, 12, COAT_LIGHT, 2.0)
	draw_arc(Vector2(30, -74), 11.0, -2.8, -0.9, 12, COAT_LIGHT, 1.6)
	# Ribs, barely visible on a lean mountain horse.
	for i in 3:
		var x := -6.0 + i * 8.0
		draw_arc(Vector2(x, -68), 12.0, 0.6, 1.4, 6, COAT_SHADE, 1.0)
	# Elbow and stifle creases.
	draw_line(Vector2(22, -60), Vector2(26, -66), COAT_SHADE, 1.4)
	draw_line(Vector2(-40, -62), Vector2(-33, -70), COAT_SHADE, 1.4)


func _draw_neck_and_head() -> void:
	var neck_xf := Transform2D(_head_nod * 0.5, Vector2(36, -88))
	var neck := PackedVector2Array([
		Vector2(-12, -8), Vector2(0, -20), Vector2(14, -32), Vector2(24, -38), Vector2(30, -34),
		Vector2(28, -20), Vector2(22, -6), Vector2(14, 14), Vector2(4, 26), Vector2(-6, 20),
	])
	draw_set_transform_matrix(_body_xf() * neck_xf)
	draw_colored_polygon(neck, COAT)
	draw_polyline(PackedVector2Array([Vector2(20, -4), Vector2(12, 12), Vector2(4, 22)]), COAT_SHADE, 2.0)
	draw_polyline(PackedVector2Array([Vector2(-6, -12), Vector2(6, -24), Vector2(18, -34)]), COAT_LIGHT, 1.6)
	# Mane: strands stream backwards with speed.
	var flow := 4.0 + speed_ratio * 10.0
	for i in 9:
		var t := i / 8.0
		var root := Vector2(-10, -10).lerp(Vector2(24, -38), t)
		var wave := sin(_time * (6.0 + speed_ratio * 10.0) + i * 0.9) * (1.0 + speed_ratio * 2.5)
		var tip := root + Vector2(-flow - 4.0 + wave, 7.0 - speed_ratio * 4.0 + wave * 0.4)
		var mid := root.lerp(tip, 0.5) + Vector2(0, -2.0)
		draw_polyline(PackedVector2Array([root, mid, tip]), MANE, 2.6 - t * 0.8)
	# Head.
	var head_xf := Transform2D(0.55 + _head_nod, Vector2(26, -34))
	draw_set_transform_matrix(_body_xf() * neck_xf * head_xf)
	var head := PackedVector2Array([
		Vector2(-4, -6), Vector2(6, -9), Vector2(20, -8), Vector2(32, -5), Vector2(38, 0),
		Vector2(37, 7), Vector2(30, 10), Vector2(18, 9), Vector2(8, 12), Vector2(-2, 10),
	])
	draw_colored_polygon(head, COAT)
	# Cheek and jaw.
	draw_arc(Vector2(5, 3), 7.0, 0.2, 2.6, 10, COAT_SHADE, 1.6)
	# Muzzle darker, white blaze down the face.
	draw_colored_polygon(PackedVector2Array([Vector2(28, -5), Vector2(38, 0), Vector2(37, 7), Vector2(30, 10), Vector2(27, 4)]), COAT_SHADE)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -8.5), Vector2(14, -8.6), Vector2(31, -4.2), Vector2(29, -2.6), Vector2(12, -6)]), BLAZE)
	draw_circle(Vector2(35, 1.5), 1.4, Color("#140c08"))  # nostril
	draw_line(Vector2(30, 8.5), Vector2(36, 6.5), Color("#2a1810"), 1.0)  # lip line
	# Eye with lid and catchlight.
	draw_circle(Vector2(9, -3), 2.6, Color("#140c08"))
	draw_circle(Vector2(9.8, -3.8), 0.8, Color(1, 1, 1, 0.8))
	draw_arc(Vector2(9, -3), 3.4, PI + 0.3, TAU - 0.3, 6, COAT_SHADE, 1.0)
	# Ears, one flicks now and then; forelock between them.
	var flick := _ear_flick * 0.5
	draw_colored_polygon(PackedVector2Array([Vector2(-1, -6), Vector2(-4, -17 + flick * 4.0), Vector2(3, -8)]), COAT_SHADE)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -7), Vector2(1 + flick * 4.0, -18), Vector2(6, -8)]), COAT)
	draw_polyline(PackedVector2Array([Vector2(2, -8), Vector2(7, -4), Vector2(10 - speed_ratio * 4.0, 0)]), MANE, 2.0)
	if saddled:
		# Bridle: headpiece, noseband, brass rosette, bit ring.
		draw_line(Vector2(2, -8), Vector2(4, 10), LEATHER, 1.8)
		draw_line(Vector2(26, -5), Vector2(27, 9), LEATHER, 1.8)
		draw_line(Vector2(4, -2), Vector2(26, -2), LEATHER, 1.4)
		draw_circle(Vector2(4, 0), 1.7, BRASS)
		draw_arc(Vector2(30, 9), 2.2, 0.0, TAU, 8, BRASS, 1.1)
	draw_set_transform_matrix(_body_xf())


func _draw_tail() -> void:
	var root := Vector2(-52, -90)
	var lift := _tail_lift
	var swish := sin(_time * (1.3 + speed_ratio * 7.0)) * (3.0 + speed_ratio * 4.0)
	draw_circle(root, 5.0, MANE)
	for i in 8:
		var spread := (i - 3.5) * 1.6
		var length := 40.0 + (i % 3) * 5.0
		var down := Vector2(-6.0 + spread, length)
		var streamed := Vector2(-length * 0.95, 6.0 + spread)
		var tip := root + down.lerp(streamed, lift) + Vector2(swish * (0.5 + i * 0.1), 0)
		var c1 := root + Vector2(-8, 6).lerp(Vector2(-14, -2), lift)
		var c2 := root.lerp(tip, 0.65) + Vector2(spread * 0.6, -lift * 3.0)
		draw_polyline(PackedVector2Array([root, c1, c2, tip]), MANE if i % 2 == 0 else MANE.lightened(0.08), 3.0 - absf(spread) * 0.25)


func _draw_tack() -> void:
	# Khevsur saddle blanket: dark wool with red border and pale crosses.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -94), Vector2(16, -97), Vector2(20, -72), Vector2(-24, -70),
	]), BLANKET_DARK)
	draw_polyline(PackedVector2Array([
		Vector2(-22, -94), Vector2(16, -97), Vector2(20, -72), Vector2(-24, -70), Vector2(-22, -94),
	]), BLANKET, 2.6)
	for cx in [-12.0, 0.0, 11.0]:
		var c := Vector2(cx, -79)
		draw_line(c + Vector2(-3, 0), c + Vector2(3, 0), BLANKET_CROSS, 1.4)
		draw_line(c + Vector2(0, -3), c + Vector2(0, 3), BLANKET_CROSS, 1.4)
	for fx in range(-23, 20, 4):
		draw_line(Vector2(fx, -70.5), Vector2(fx - 1, -66.5), BLANKET, 1.0)  # fringe
	# Wooden-tree saddle with raised pommel and cantle.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -96), Vector2(-16, -104), Vector2(-10, -99), Vector2(6, -99), Vector2(12, -106),
		Vector2(15, -97), Vector2(10, -91), Vector2(-14, -91),
	]), LEATHER)
	draw_polyline(PackedVector2Array([Vector2(-10, -99), Vector2(6, -99)]), LEATHER.lightened(0.25), 1.4)
	draw_circle(Vector2(12, -105), 1.6, BRASS)
	# Girth, breast collar and a stirrup swinging with the stride.
	draw_line(Vector2(2, -92), Vector2(4, -53), LEATHER, 3.0)
	draw_line(Vector2(14, -94), Vector2(46, -78), LEATHER, 2.4)
	draw_circle(Vector2(30, -86), 1.8, BRASS)
	var sway := sin(cycle * TAU) * 3.0 * speed_ratio
	var stirrup := Vector2(-2 + sway, -66)
	draw_line(Vector2(-2, -92), stirrup, LEATHER, 1.6)
	draw_arc(stirrup + Vector2(0, 3), 3.4, 0.0, TAU, 8, Color("#7d7a73"), 1.4)
	# Reins from the bit ring back toward the rider's hands.
	var bit := Transform2D(_head_nod * 0.5, Vector2(36, -88)) * Transform2D(0.55 + _head_nod, Vector2(26, -34)) * Vector2(30, 9)
	draw_polyline(PackedVector2Array([bit, bit.lerp(Vector2(14, -100), 0.5) + Vector2(0, 6), Vector2(14, -100)]), LEATHER, 1.3)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
