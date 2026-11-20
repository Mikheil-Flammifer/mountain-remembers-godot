extends "res://scripts/levels/jvari/jvari_level.gd"
## Focused, backwards-compatible Jvari terrain/art upgrade.
## The existing jvari_level.gd (enemies, saves, HUD, camera and story) is untouched.
## Scene order: Confluence -> Pilgrim Road -> Stone Ascent -> Monastery -> Windcut.

const ROAD_CLIMB: float = 850.0
const RAVINE_DROP: float = 72.0

# A real continuously walkable hillside, not 25 rectangular stair risers.
func _pilgrim_ground_at(x: float) -> float:
	var t: float = clampf((x - 240.0) / maxf(area_width - 570.0, 1.0), 0.0, 1.0)
	return GROUND_Y - ROAD_CLIMB * t * t * (3.0 - 2.0 * t)

# Ravine descends only 72 pixels over the entire 7600-pixel level.
func _ravine_ground_at(x: float) -> float:
	var t: float = clampf(x / maxf(area_width, 1.0), 0.0, 1.0)
	return GROUND_Y + RAVINE_DROP * t + 3.0 * sin(t * TAU * 2.0)

func _ground_height_at(x: float) -> float:
	match area_index:
		1:
			return _pilgrim_ground_at(x)
		2:
			return _ravine_ground_at(x)
		3:
			return _ascent_ground_at(x)
	return GROUND_Y

# A single slope collider with the same profile as the rendered uphill trail.
func _build_pilgrim_ascent() -> void:
	_make_solid("LeftBoundary", Vector2(-16.0, -250.0), Vector2(32.0, 2200.0))
	_make_solid("RightBoundary", Vector2(area_width + 16.0, -250.0), Vector2(32.0, 2200.0))
	_add_slope_collider("PilgrimRoadGround", 0.0, area_width, 1550.0)
	# No floating ledges, risers or blocking boulders: the road itself is the climb.

func _build_terrain() -> void:
	if area_index == 4:
		# The original monastery PIT_LAYOUTS includes x=7160..7390.
		# That hole is directly under the church door at x=7220.
		# Make the whole monastery approach one safe, walkable courtyard.
		_pits.clear()
		_ground_sections.clear()
		_platforms.clear()
		_pillars.clear()
		_add_ground_section(0.0, area_width)
		_make_solid("LeftBoundary", Vector2(-16.0, 230.0), Vector2(32.0, 1100.0))
		_make_solid("RightBoundary", Vector2(area_width + 16.0, 230.0), Vector2(32.0, 1100.0))
		return
	super._build_terrain()
	if area_index == 2:
		# The original obstacles were placed on y=650. Follow the new grade.
		for child in get_children():
			if child.name.begins_with("RockObstruction_") and child is StaticBody2D:
				child.position.y += _ravine_ground_at(child.position.x) - GROUND_Y

func _add_ground_section(start_x: float, end_x: float) -> void:
	if area_index != 2:
		super._add_ground_section(start_x, end_x)
		return
	if end_x - start_x <= 5.0:
		return
	_ground_sections.append(Vector2(start_x, end_x))
	_add_slope_collider("RavineGround_%d" % int(start_x), start_x, end_x, 1170.0)

func _add_slope_collider(body_name: String, start_x: float, end_x: float, bottom_y: float) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = 1
	body.collision_mask = 1
	var polygon := PackedVector2Array()
	var samples: int = maxi(2, ceili((end_x - start_x) / 44.0))
	for i in range(samples + 1):
		var x: float = lerpf(start_x, end_x, float(i) / float(samples))
		polygon.append(Vector2(x, _ground_height_at(x)))
	polygon.append(Vector2(end_x, bottom_y))
	polygon.append(Vector2(start_x, bottom_y))
	var shape := CollisionPolygon2D.new()
	shape.polygon = polygon
	body.add_child(shape)
	add_child(body)

func _build_challenges() -> void:
	# Monastery is peaceful: no spikes, falling stones, gust traps or boars.
	if area_index == 4:
		return
	super._build_challenges()

func _draw() -> void:
	# Explicitly move the distant Jvari silhouette to Pilgrim Road.
	# Keep the large second monastery at x=7220 in the monastery area.
	_draw_sky()
	_draw_mountains()
	if area_index == 1:
		_draw_jvari_distant_view()
	_draw_signature_landscape()
	if area_index == 0:
		_draw_confluence()
	_draw_road()
	if area_index == 0:
		_draw_wide_river()
	_draw_trees()
	_draw_local_landmarks()
	if area_index == 4:
		_draw_monastery(7220.0, 2.2, 645.0)

func _draw_road() -> void:
	if area_index == 2:
		_draw_windcut_path()
		return
	super._draw_road()

func _draw_pilgrim_road() -> void:
	var soil := PackedVector2Array()
	var samples: int = ceili(area_width / 38.0)
	for i in range(samples + 1):
		var x: float = area_width * float(i) / float(samples)
		soil.append(Vector2(x, _pilgrim_ground_at(x)))
	soil.append(Vector2(area_width, 1550.0))
	soil.append(Vector2(0.0, 1550.0))
	draw_colored_polygon(soil, Color("#756a54"))
	# Continuous dusty ridge; no visually separate steps.
	for i in range(samples):
		var left_x: float = area_width * float(i) / float(samples)
		var right_x: float = area_width * float(i + 1) / float(samples)
		draw_line(Vector2(left_x, _pilgrim_ground_at(left_x)), Vector2(right_x, _pilgrim_ground_at(right_x)), Color("#d5bf98"), 10.0, true)
		draw_line(Vector2(left_x, _pilgrim_ground_at(left_x) + 14.0), Vector2(right_x, _pilgrim_ground_at(right_x) + 14.0), Color("#90806a"), 3.0, true)
	# Embedded stones, masonry courses and scrub keep it detailed but walkable.
	for i in range(135):
		var x: float = 22.0 + float(i) * 51.0
		if x >= area_width - 20.0:
			break
		var y: float = _pilgrim_ground_at(x)
		var w: float = 14.0 + float((i * 11) % 7) * 3.0
		var h: float = 5.0 + float((i * 7) % 5) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 1.0), Vector2(x + w * 0.46, y - h), Vector2(x + w, _pilgrim_ground_at(x + w) - 1.0)]), Color("#aca085") if i % 3 == 0 else Color("#8a826d"))
	for i in range(57):
		var x: float = 75.0 + float(i) * 120.0
		var y: float = _pilgrim_ground_at(x)
		draw_line(Vector2(x, y + 52.0), Vector2(x + 96.0, _pilgrim_ground_at(x + 96.0) + 52.0), Color("#5b5548", 0.55), 1.7)
		draw_line(Vector2(x + 45.0, y + 20.0), Vector2(x + 45.0, y + 51.0), Color("#c2ac87", 0.36), 1.2)
	for i in range(29):
		var x: float = 105.0 + float(i) * 233.0
		var y: float = _pilgrim_ground_at(x)
		draw_line(Vector2(x, y), Vector2(x - 3.0, y - 14.0), Color("#687b56"), 2.0)
		draw_line(Vector2(x - 3.0, y - 14.0), Vector2(x + 8.0, y - 4.0), Color("#91a06c"), 1.5)

func _draw_ascent_road() -> void:
	# Preserve all 31 real jumpable stone risers and their collision geometry.
	super._draw_ascent_road()
	# Add readable top edges, limestone wear, masonry and small mountain grasses.
	for i in range(_ascent_steps.size()):
		var terrace: Vector3 = _ascent_steps[i]
		var left: float = terrace.x
		var right: float = terrace.y
		var y: float = terrace.z
		draw_line(Vector2(left, y), Vector2(right, y), Color("#e4d3ad", 0.90), 3.0)
		for row in range(6):
			var cy: float = y + 32.0 + float(row) * 34.0
			var sx: float = left + 30.0 + float((i + row) % 3) * 16.0
			while sx < right - 11.0:
				draw_line(Vector2(sx, cy), Vector2(sx + 5.0, cy + 12.0), Color("#4b4d43", 0.44), 1.4)
				sx += 57.0
		for k in range(4):
			var px: float = left + 22.0 + float(k) * 56.0
			if px < right - 12.0:
				draw_circle(Vector2(px, y - 2.0), 2.2, Color("#d2c7a6"))
		if i % 4 == 1:
			var grass_x: float = left + minf(94.0, (right-left) * 0.55)
			draw_line(Vector2(grass_x, y), Vector2(grass_x - 5.0, y - 14.0), Color("#778861"), 2.0)
			draw_line(Vector2(grass_x, y), Vector2(grass_x + 7.0, y - 12.0), Color("#9aa376"), 2.0)

func _draw_windcut_path() -> void:
	for section: Vector2 in _ground_sections:
		var left: float = section.x
		var right: float = section.y
		var n: int = maxi(2, ceili((right - left) / 39.0))
		var ground_polygon := PackedVector2Array()
		for i in range(n + 1):
			var x: float = lerpf(left, right, float(i) / float(n))
			ground_polygon.append(Vector2(x, _ravine_ground_at(x)))
		ground_polygon.append(Vector2(right, 1170.0))
		ground_polygon.append(Vector2(left, 1170.0))
		draw_colored_polygon(ground_polygon, Color("#606655"))
		for i in range(n):
			var x: float = lerpf(left, right, float(i) / float(n))
			var nx: float = lerpf(left, right, float(i + 1) / float(n))
			draw_line(Vector2(x, _ravine_ground_at(x)), Vector2(nx, _ravine_ground_at(nx)), Color("#bcb49a"), 7.0, true)
			draw_line(Vector2(x, _ravine_ground_at(x) + 12.0), Vector2(nx, _ravine_ground_at(nx) + 12.0), Color("#859380"), 2.0, true)
	for i in range(94):
		var x: float = 22.0 + float(i) * 80.0
		if _near_gap(x, 25.0):
			continue
		var y: float = _ravine_ground_at(x)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 15.0, y), Vector2(x, y - 7.0 - float(i % 3) * 3.0), Vector2(x + 17.0, y + 2.0)]), Color("#989982") if i % 4 == 0 else Color("#858d79"))
		draw_line(Vector2(x + 3.0, y + 37.0), Vector2(x + 64.0, _ravine_ground_at(x + 64.0) + 38.0), Color("#424d45", 0.46), 1.4)
	for platform: Vector2 in _platforms:
		draw_rect(Rect2(platform.x - 84.0, platform.y, 168.0, 17.0), Color("#7e8170"))
		draw_rect(Rect2(platform.x - 84.0, platform.y, 168.0, 5.0), Color("#c2b598"))
	for pillar: Vector2 in _pillars:
		var base_y: float = _ravine_ground_at(pillar.x)
		draw_rect(Rect2(pillar.x - 29.0, base_y - pillar.y, 58.0, pillar.y), Color("#626a5e"))
		draw_rect(Rect2(pillar.x - 31.0, base_y - pillar.y - 7.0, 62.0, 9.0), Color("#a8aa90"))
	for pit: Vector2 in _pits:
		draw_rect(Rect2(pit.x, _ravine_ground_at(pit.x) + 16.0, pit.y - pit.x, 330.0), Color("#303d3b"))
		draw_line(Vector2(pit.x, _ravine_ground_at(pit.x)), Vector2(pit.x + 18.0, _ravine_ground_at(pit.x) + 51.0), Color("#b6a38a"), 3.0)
		draw_line(Vector2(pit.y, _ravine_ground_at(pit.y)), Vector2(pit.y - 18.0, _ravine_ground_at(pit.y) + 51.0), Color("#b6a38a"), 3.0)

func _draw_signature_landscape() -> void:
	super._draw_signature_landscape()
	if area_index == 1:
		# Sparse contours behind the road emphasize the climb rather than steps.
		for i in range(15):
			var x: float = 145.0 + float(i) * 440.0
			var y: float = _pilgrim_ground_at(x) - 227.0
			draw_line(Vector2(x - 60.0, y), Vector2(x + 105.0, y - 21.0), Color("#d5c6a4", 0.32), 2.0)
	elif area_index == 2:
		# Dark shale fissures, layered cliffs, and high thin mist.
		for i in range(13):
			var x: float = 240.0 + float(i) * 585.0
			var y: float = 342.0 + float(i % 4) * 45.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 220.0, 650.0), Vector2(x - 125.0, y + 65.0), Vector2(x - 56.0, y + 4.0), Vector2(x + 62.0, y + 85.0), Vector2(x + 130.0, 690.0)]), Color("#455a55", 0.27))
			draw_line(Vector2(x - 74.0, y + 26.0), Vector2(x + 22.0, y + 61.0), Color("#9cae9f", 0.24), 2.0)
		for i in range(17):
			var x: float = 60.0 + float(i) * 455.0
			var y: float = 300.0 + float(i % 4) * 49.0
			draw_line(Vector2(x, y), Vector2(x + 290.0, y - 10.0), Color("#e1e1d1", 0.18), 13.0)

func _draw_trees() -> void:
	if area_index != 2:
		super._draw_trees()
		return
	for i in range(28):
		var x: float = 150.0 + float(i) * 265.0
		if _near_gap(x, 85.0):
			continue
		var y: float = _ravine_ground_at(x)
		var h: float = 46.0 + float((i * 11) % 5) * 10.0
		draw_line(Vector2(x, y), Vector2(x - 8.0, y - h), Color("#414f43"), 5.0)
		draw_circle(Vector2(x - 19.0, y - h), h * 0.37, Color("#4e6b59", 0.88))
		draw_circle(Vector2(x + 3.0, y - h * 0.88), h * 0.29, Color("#738a71", 0.78))

func _draw_local_landmarks() -> void:
	if area_index != 2:
		super._draw_local_landmarks()
		return
	for i in range(13):
		var x: float = 540.0 + float(i) * 525.0
		var y: float = _ravine_ground_at(x)
		draw_line(Vector2(x, y), Vector2(x - 32.0, y - 138.0), Color("#444f46"), 7.0)
		draw_circle(Vector2(x - 48.0, y - 137.0), 35.0, Color("#57705f", 0.78))
	_draw_cross(3850.0, _ravine_ground_at(3850.0), 0.60)

# Return to the original clean, complete Jvari silhouette.
# Subtle masonry and ceramic roof detail is added without replacing the architecture.
# This is visual only: the existing entrance, terrain, NPCs, and transitions stay intact.
func _draw_monastery(x: float, scale_factor: float, location_y: float = 480.0) -> void:
	# Let the original jvari_level.gd draw its well-proportioned complete church.
	super._draw_monastery(x, scale_factor, location_y)
	var f: float = scale_factor
	var p := Vector2(x, location_y)
	var mortar := Color("#6e6354", 0.23)
	var sunlit := Color("#ede0c5", 0.22)

	# Readable but restrained stone courses on central facade.
	# Preserve the original window, apse silhouette, doorway and cross.
	for row in range(4):
		var yy: float = -108.0 + float(row) * 26.0
		draw_line(p + Vector2(-96.0, yy) * f, p + Vector2(96.0, yy) * f, mortar, maxf(0.7, 0.75 * f))
		for joint in range(3):
			var xx: float = -67.0 + float(joint) * 67.0 + float(row % 2) * 16.0
			# Shallow chisel joints, not large missing stones.
			draw_line(p + Vector2(xx, yy) * f, p + Vector2(xx + 2.0, yy + 10.0) * f, mortar, maxf(0.7, 0.65 * f))
	# Highlights on stone edges, kept away from the main entrance.
	draw_line(p + Vector2(-101.0, -117.0) * f, p + Vector2(-101.0, -5.0) * f, sunlit, maxf(0.8, 1.0 * f))
	draw_line(p + Vector2(101.0, -117.0) * f, p + Vector2(101.0, -5.0) * f, mortar, maxf(0.8, 1.0 * f))
	for side in [-1.0, 1.0]:
		# A few dressed joints on the shorter arms.
		var left: float = -153.0 if side < 0.0 else 93.0
		for row in range(2):
			var yy: float = -63.0 + float(row) * 29.0
			draw_line(p + Vector2(left, yy) * f, p + Vector2(left + 59.0, yy) * f, mortar, maxf(0.7, 0.7 * f))

	# Ceramic tile colors, following the EXACT roofs of the original design.
	# Central pyramid, low left/right arms, and the triangular front gable.
	_draw_simple_ceramic_roof(p, f, Vector2(0.0, -242.0), -64.0, 64.0, -198.0)
	_draw_simple_ceramic_roof(p, f, Vector2(-118.0, -110.0), -51.0, 53.0, -87.0)
	_draw_simple_ceramic_roof(p, f, Vector2(115.0, -117.0), -50.0, 51.0, -91.0)
	# Original facade gable is limestone, not a ceramic roof; leave it unchanged.

	# Small carved stone relief above the door: understated cross medallion.
	var carving: Color = Color("#746755", 0.55)
	draw_arc(p + Vector2(0.0, -55.0) * f, 12.0 * f, 0.0, TAU, 18, carving, maxf(0.7, 0.9 * f))
	draw_line(p + Vector2(0.0, -63.0) * f, p + Vector2(0.0, -47.0) * f, carving, maxf(0.7, 1.0 * f))
	draw_line(p + Vector2(-7.0, -55.0) * f, p + Vector2(7.0, -55.0) * f, carving, maxf(0.7, 1.0 * f))


func _draw_simple_ceramic_roof(p: Vector2, f: float, peak: Vector2, left_x: float, right_x: float, bottom_y: float) -> void:
	var roof_color := Color("#966952")
	var tile_light := Color("#ba8866", 0.76)
	var tile_dark := Color("#664b3e", 0.55)
	var left := Vector2(peak.x + left_x, bottom_y)
	var right := Vector2(peak.x + right_x, bottom_y)
	draw_colored_polygon(PackedVector2Array([p + left * f, p + peak * f, p + right * f]), roof_color)
	var depth: float = bottom_y - peak.y
	if depth <= 1.0:
		return
	# Restrict every line to the sloping roof, never across the building.
	for i in range(1, 5):
		var t: float = float(i) / 5.0
		var yy: float = lerpf(peak.y, bottom_y, t)
		var xl: float = lerpf(peak.x, left.x, t)
		var xr: float = lerpf(peak.x, right.x, t)
		draw_line(p + Vector2(xl, yy) * f, p + Vector2(xr, yy) * f, tile_light, maxf(0.8, 0.85 * f))
		var count: int = maxi(1, int((xr - xl) / 20.0))
		for tile in range(1, count):
			var tx: float = lerpf(xl, xr, float(tile) / float(count))
			draw_line(p + Vector2(tx, yy - 2.0) * f, p + Vector2(tx + 1.0, yy + 2.0) * f, tile_dark, maxf(0.6, 0.55 * f))
