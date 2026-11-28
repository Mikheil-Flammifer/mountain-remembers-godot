extends RefCounted
## Shared hand-drawn landscape for outdoor Mtskheta scenes.
## Warm sage/olive hills with smooth, sampled ridge curves.
## Decorative only; never creates collision shapes.

const SKY_TOP := Color("#e9d8b7")
const SKY_HORIZON := Color("#d7c7a5")
const HILL_FAR := Color("#a9ae86")
const HILL_MIDDLE := Color("#859775")
const HILL_NEAR := Color("#637d60")
const RIDGE_LIGHT := Color("#d8c7a3")

## Far and middle hills scroll slower than the hero (two parallax layers).
const FAR_SCROLL := 0.25
const MIDDLE_SCROLL := 0.55
const BACKDROP_NODE := "ParallaxBackdrop"
const SELF_PATH := "res://scripts/levels/mtskheta/shared/mtskheta_landscape.gd"
const RidgeLayer = preload("res://scripts/levels/mtskheta/shared/parallax_ridge_layer.gd")

static func draw_landscape(canvas: CanvasItem, width: float, ground_y: float, variant: float = 0.0) -> void:
	# Sky, far hills and middle hills live in Parallax2D layers behind the level;
	# the near hills stay in the level drawing so they move with the ground.
	if not canvas.has_node(BACKDROP_NODE):
		_build_parallax_backdrop.call_deferred(canvas, width, ground_y, variant)

	_draw_ridge(canvas, width, ground_y, 550.0, 42.0, 330.0, 2.8 + variant * 0.5, HILL_NEAR)

	# Faint contour line emphasizes the rolling ridge without visual noise.
	for n in range(6):
		var x: float = 140.0 + float(n) * (width / 6.0)
		var y: float = 516.0 + 11.0 * sin(x / 310.0 + variant)
		canvas.draw_line(Vector2(x, y), Vector2(minf(x + 68.0, width), y + 3.0), Color(RIDGE_LIGHT, 0.17), 1.0)

static func draw_sky(canvas: CanvasItem, width: float, ground_y: float) -> void:
	# A restrained warm gradient; avoid a cold blue-green filter.
	var top: float = -560.0
	var bottom: float = ground_y + 15.0
	var strips: int = 30
	for i in range(strips):
		var t: float = float(i) / float(strips - 1)
		var y: float = lerpf(top, bottom, t)
		canvas.draw_rect(Rect2(0.0, y, width, (bottom - top) / float(strips) + 2.0), SKY_TOP.lerp(SKY_HORIZON, t))

static func draw_ridge_band(canvas: CanvasItem, width: float, ground_y: float, base_y: float, amplitude: float, wavelength: float, phase: float, tint: Color) -> void:
	_draw_ridge(canvas, width, ground_y, base_y, amplitude, wavelength, phase, tint)

static func _build_parallax_backdrop(canvas: CanvasItem, width: float, ground_y: float, variant: float) -> void:
	if not is_instance_valid(canvas) or canvas.has_node(BACKDROP_NODE):
		return
	var root := Node2D.new()
	root.name = BACKDROP_NODE
	canvas.add_child(root)
	# Sky is pinned to the screen; hills move at a fraction of the camera speed.
	_add_layer(root, -100, Vector2(0.0, 1.0), &"sky", width, ground_y, 0.0, 0.0, 1.0, 0.0, Color.WHITE)
	_add_layer(root, -99, Vector2(FAR_SCROLL, 1.0), &"ridge", width, ground_y, 382.0, 56.0, 480.0, 0.4 + variant, HILL_FAR)
	_add_layer(root, -98, Vector2(MIDDLE_SCROLL, 1.0), &"ridge", width, ground_y, 462.0, 55.0, 405.0, 1.7 + variant * 0.7, HILL_MIDDLE)

static func _add_layer(root: Node2D, z: int, scroll: Vector2, kind: StringName, width: float, ground_y: float, base_y: float, amplitude: float, wavelength: float, phase: float, tint: Color) -> void:
	var parallax := Parallax2D.new()
	parallax.scroll_scale = scroll
	parallax.z_index = z
	var layer := RidgeLayer.new()
	layer.painter = load(SELF_PATH)
	layer.kind = kind
	layer.width = width
	layer.ground_y = ground_y
	layer.base_y = base_y
	layer.amplitude = amplitude
	layer.wavelength = wavelength
	layer.phase = phase
	layer.tint = tint
	parallax.add_child(layer)
	root.add_child(parallax)

static func _ridge_y(x: float, base_y: float, amplitude: float, wavelength: float, phase: float) -> float:
	var a: float = sin((x / wavelength) + phase)
	var b: float = sin((x / (wavelength * 0.49)) + phase * 0.67)
	var c: float = sin((x / (wavelength * 1.9)) - phase * 0.41)
	return base_y - amplitude * (0.55 * a + 0.27 * b + 0.18 * c)

static func _draw_ridge(canvas: CanvasItem, width: float, ground_y: float, base_y: float, amplitude: float, wavelength: float, phase: float, tint: Color) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(0.0, ground_y + 30.0))
	var count: int = ceili(width / 18.0)
	for i in range(count + 1):
		var x: float = minf(float(i) * 18.0, width)
		points.append(Vector2(x, _ridge_y(x, base_y, amplitude, wavelength, phase)))
	points.append(Vector2(width, ground_y + 30.0))
	canvas.draw_colored_polygon(points, tint)

static func draw_jvari(canvas: CanvasItem, x: float, base_y: float, scale_value: float = 1.0) -> void:
	# Distant Jvari cross-in-square church: low pitched roofs, raised central drum.
	# Stylized silhouette, not an exact architectural elevation.
	var offset := Vector2(x, base_y)
	canvas.draw_set_transform(offset, 0.0, Vector2.ONE * scale_value)
	var stone := Color("#55574b")
	var sunlit := Color("#898a6d")
	var roof := Color("#454d44")
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-90, 9), Vector2(-54, -3), Vector2(-20, -12),
		Vector2(24, -9), Vector2(67, 5), Vector2(96, 18),
		Vector2(96, 31), Vector2(-90, 31)
	]), Color("#708060"))
	# Side apses and compact rectangular nave.
	canvas.draw_rect(Rect2(-37, -28, 74, 36), stone)
	canvas.draw_rect(Rect2(-51, -19, 16, 26), sunlit)
	canvas.draw_rect(Rect2(36, -19, 16, 26), stone)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-45, -28), Vector2(0, -48), Vector2(45, -28)
	]), roof)
	# Squat faceted drum with pitched roof and cross.
	canvas.draw_rect(Rect2(-13, -57, 26, 23), sunlit)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -57), Vector2(0, -74), Vector2(18, -57)
	]), roof)
	canvas.draw_line(Vector2(0, -86), Vector2(0, -73), stone, 2.3)
	canvas.draw_line(Vector2(-5, -82), Vector2(5, -82), stone, 2.0)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
