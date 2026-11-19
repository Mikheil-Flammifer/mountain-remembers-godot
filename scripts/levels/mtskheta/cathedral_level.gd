extends Node2D
# SHARED_WARM_GREEN_LANDSCAPE
const Landscape = preload("res://scripts/levels/mtskheta/shared/mtskheta_landscape.gd")

## Svetitskhoveli Cathedral environment.
##
## The cathedral composition is based on the supplied front-view reference:
## - broad horizontal nave
## - three-arch gallery on the left
## - flat right-side wall with small narrow windows
## - projecting central Georgian facade
## - warmer central drum/tower
## - tall ribbed conical dome
##
## This is intentionally NOT a generic medieval church silhouette.

@export_group("Scene")
@export var ground_y: float = 650.0
@export var level_width: float = 2400.0

@export_group("Cathedral")
@export var cathedral_center_x: float = 1200.0
@export var cathedral_scale: float = 0.82

const SKY := Color("#d9c1a4")
const MOUNTAIN_FAR := Color("#a88f78")
const MOUNTAIN_NEAR := Color("#80725a")

const COURTYARD := Color("#8e765e")

const STONE_MAIN := Color("#b6a086")
const STONE_LIGHT := Color("#d2b99a")
const STONE_MID := Color("#9b8066")
const STONE_DARK := Color("#675445")
const STONE_SHADOW := Color("#51463c")

# The tower/drum is visibly warmer than the main facade
# in the supplied reference.
const DRUM_STONE := Color("#a58864")
const DRUM_LIGHT := Color("#c9a87e")
const DRUM_DARK := Color("#78604a")

const ROOF := Color("#857264")
const ROOF_LIGHT := Color("#ab937d")
const DOME := Color("#756354")
const DOME_RIB := Color("#a88d70")

const WINDOW := Color("#3e342d")
const WOOD := Color("#70482f")

const TREE_DARK := Color("#596044")
const TREE_LIGHT := Color("#7a8050")


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _draw() -> void:
	_draw_background()
	_draw_courtyard()

	var base_y: float = ground_y - 95.0

	draw_set_transform(
		Vector2(cathedral_center_x, base_y),
		0.0,
		Vector2(cathedral_scale, cathedral_scale)
	)

	_draw_svetitskhoveli()

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)

	_draw_foreground()

func _draw_background() -> void:
	# Landscape only; the existing detailed cathedral drawing is untouched.
	Landscape.draw_landscape(self, level_width, ground_y, 0.64)

func _draw_courtyard() -> void:
	draw_rect(
		Rect2(
			0.0,
			ground_y - 95.0,
			level_width,
			95.0
		),
		COURTYARD
	)

	for i in range(35):
		var x: float = float(i) * 72.0

		draw_line(
			Vector2(x, ground_y - 95.0),
			Vector2(x, ground_y),
			Color(0.31, 0.30, 0.28, 0.18),
			1.0
		)

	for i in range(4):
		var y: float = ground_y - 80.0 + float(i) * 22.0

		draw_line(
			Vector2(0.0, y),
			Vector2(level_width, y),
			Color(0.31, 0.30, 0.28, 0.18),
			1.0
		)

func _draw_svetitskhoveli() -> void:
		# ============================================================
	# 1. UPPER ROOF
	# ============================================================
	#
	# Keep the upper roof almost exactly as before.
	# This is the long roof immediately beneath the drum.

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-325.0, -250.0),
			Vector2(-295.0, -272.0),
			Vector2(295.0, -272.0),
			Vector2(325.0, -250.0)
		]),
		ROOF
	)

	draw_line(
		Vector2(-295.0, -271.0),
		Vector2(295.0, -271.0),
		ROOF_LIGHT,
		2.0
	)


	# ============================================================
	# 2. MIDDLE BAND BETWEEN THE TWO ROOFS
	# ============================================================
	#
	# This is the part you pointed out in the reference:
	#
	# LEFT:
	# recessed arcade / concave arches
	#
	# RIGHT:
	# mostly flat wall with many narrow windows
	#
	# Both parts sit BETWEEN the upper and lower roofs.

	# -----------------------------
	# LEFT MIDDLE WALL
	# -----------------------------

	draw_rect(
		Rect2(
			-315.0,
			-248.0,
			205.0,
			105.0
		),
		STONE_MAIN
	)

	# Three deep rounded openings.
	_draw_arch_opening(
		Rect2(
			-297.0,
			-215.0,
			44.0,
			72.0
		),
		STONE_SHADOW
	)

	_draw_arch_opening(
		Rect2(
			-238.0,
			-215.0,
			44.0,
			72.0
		),
		STONE_SHADOW
	)

	_draw_arch_opening(
		Rect2(
			-179.0,
			-215.0,
			44.0,
			72.0
		),
		STONE_SHADOW
	)

	# Vertical stone strips between arches.
	for x in [
		-305.0,
		-246.0,
		-187.0,
		-128.0
	]:
		draw_rect(
			Rect2(
				x,
				-207.0,
				8.0,
				64.0
			),
			STONE_LIGHT
		)


	# -----------------------------
	# RIGHT MIDDLE WALL
	# -----------------------------

	draw_rect(
		Rect2(
			110.0,
			-248.0,
			205.0,
			105.0
		),
		STONE_MAIN
	)

	# Horizontal row of small narrow windows,
	# matching the photograph.
	for i in range(7):
		var window_x: float = 128.0 + float(i) * 24.0

		_draw_arch_opening(
			Rect2(
				window_x,
				-208.0,
				10.0,
				38.0
			),
			WINDOW
		)

	# Subtle lower masonry band.
	draw_line(
		Vector2(115.0, -157.0),
		Vector2(310.0, -157.0),
		STONE_MID,
		3.0
	)


	# ============================================================
	# 3. LOWER ROOF
	# ============================================================
	#
	# This is the second roof visible in your reference.
	#
	# It sits directly BELOW the arcade/window level.
	# The big central triangular facade overlaps it.

	# LEFT lower roof
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-350.0, -143.0),
			Vector2(-320.0, -170.0),
			Vector2(-105.0, -170.0),
			Vector2(-82.0, -143.0)
		]),
		ROOF_LIGHT
	)

	# RIGHT lower roof
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(82.0, -143.0),
			Vector2(105.0, -170.0),
			Vector2(320.0, -170.0),
			Vector2(350.0, -143.0)
		]),
		ROOF_LIGHT
	)

	# Roof ridge highlights.
	draw_line(
		Vector2(-320.0, -169.0),
		Vector2(-105.0, -169.0),
		Color(0.68, 0.65, 0.60, 1.0),
		1.5
	)

	draw_line(
		Vector2(105.0, -169.0),
		Vector2(320.0, -169.0),
		Color(0.68, 0.65, 0.60, 1.0),
		1.5
	)


	# ============================================================
	# 4. LOWER WALLS BENEATH SECOND ROOF
	# ============================================================
	#
	# Very important:
	# these walls reach the SAME ground level as the central
	# projecting entrance facade.
	#
	# They are not floating side constructions.

	# LEFT lower wall
	draw_rect(
		Rect2(
			-335.0,
			-143.0,
			245.0,
			143.0
		),
		STONE_MAIN
	)

	# RIGHT lower wall
	draw_rect(
		Rect2(
			90.0,
			-143.0,
			245.0,
			143.0
		),
		STONE_MAIN
	)

	# Slight shadow along bottom masonry.
	draw_rect(
		Rect2(
			-335.0,
			-22.0,
			245.0,
			22.0
		),
		STONE_MID
	)

	draw_rect(
		Rect2(
			90.0,
			-22.0,
			245.0,
			22.0
		),
		STONE_MID
	)


	# ============================================================
	# 4A. LOWER LEFT WALL DETAILS
	# ============================================================

	_draw_arch_outline(
		Rect2(
			-300.0,
			-105.0,
			52.0,
			98.0
		),
		STONE_MID,
		3.0
	)

	_draw_arch_opening(
		Rect2(
			-286.0,
			-86.0,
			24.0,
			72.0
		),
		WINDOW
	)

	_draw_arch_outline(
		Rect2(
			-220.0,
			-91.0,
			44.0,
			84.0
		),
		STONE_MID,
		2.5
	)


	# ============================================================
	# 4B. LOWER RIGHT WALL DETAILS
	# ============================================================

	_draw_arch_outline(
		Rect2(
			245.0,
			-105.0,
			52.0,
			98.0
		),
		STONE_MID,
		3.0
	)

	_draw_arch_opening(
		Rect2(
			259.0,
			-86.0,
			24.0,
			72.0
		),
		WINDOW
	)

	_draw_arch_outline(
		Rect2(
			176.0,
			-91.0,
			44.0,
			84.0
		),
		STONE_MID,
		2.5
	)

	# ============================================================
	# 5. CENTRAL DRUM / TOWER
	# ============================================================
	#
	# Drawn BEFORE the front facade because the facade overlaps
	# the lower portion of the tower in the reference.
	#
	# This tower is a visibly warmer stone color.

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-64.0, -397.0),
			Vector2(64.0, -397.0),
			Vector2(67.0, -260.0),
			Vector2(55.0, -242.0),
			Vector2(-55.0, -242.0),
			Vector2(-67.0, -260.0)
		]),
		DRUM_STONE
	)

	# Upper tower band.
	draw_rect(
		Rect2(
			-65.0,
			-398.0,
			130.0,
			12.0
		),
		DRUM_DARK
	)

	# Lower tower band.
	draw_rect(
		Rect2(
			-62.0,
			-276.0,
			124.0,
			9.0
		),
		DRUM_DARK
	)

	# Vertical articulation around the tower.
	for x in [
		-51.0,
		-26.0,
		0.0,
		26.0,
		51.0
	]:
		draw_rect(
			Rect2(
				x - 3.0,
				-381.0,
				6.0,
				102.0
			),
			DRUM_LIGHT
		)

	# Narrow tall tower windows.
	_draw_arch_opening(
		Rect2(-41.0, -355.0, 12.0, 57.0),
		WINDOW
	)

	_draw_arch_opening(
		Rect2(-6.0, -355.0, 12.0, 57.0),
		WINDOW
	)

	_draw_arch_opening(
		Rect2(29.0, -355.0, 12.0, 57.0),
		WINDOW
	)

	# ============================================================
	# 6. CONICAL DOME
	# ============================================================

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-78.0, -397.0),
			Vector2(0.0, -535.0),
			Vector2(78.0, -397.0)
		]),
		DOME
	)

	# Dome ribs visible in the photograph.
	for x in [
		-58.0,
		-38.0,
		-19.0,
		0.0,
		19.0,
		38.0,
		58.0
	]:
		draw_line(
			Vector2(0.0, -532.0),
			Vector2(x, -401.0),
			DOME_RIB,
			1.6
		)

	# Small finial.
	draw_line(
		Vector2(0.0, -535.0),
		Vector2(0.0, -550.0),
		DOME_RIB,
		2.0
	)

	# ============================================================
	# 7. CENTRAL FRONT FACADE
	# ============================================================
	#
	# The major characteristic of the photo:
	# a tall central projection with a triangular gable and
	# descending shoulders on either side.

	var central_facade := PackedVector2Array([
		Vector2(-255.0, 0.0),

		Vector2(-255.0, -94.0),
		Vector2(-190.0, -94.0),

		Vector2(-190.0, -139.0),
		Vector2(-118.0, -139.0),

		Vector2(-118.0, -188.0),

		Vector2(0.0, -266.0),

		Vector2(118.0, -188.0),
		Vector2(118.0, -139.0),

		Vector2(190.0, -139.0),
		Vector2(190.0, -94.0),

		Vector2(255.0, -94.0),

		Vector2(255.0, 0.0)
	])

	draw_colored_polygon(
		central_facade,
		STONE_MAIN
	)

	# ============================================================
	# 8. FRONT GABLE DETAIL
	# ============================================================

	draw_line(
		Vector2(-112.0, -187.0),
		Vector2(0.0, -260.0),
		STONE_LIGHT,
		4.0
	)

	draw_line(
		Vector2(0.0, -260.0),
		Vector2(112.0, -187.0),
		STONE_LIGHT,
		4.0
	)

	# Inner decorative gable.
	draw_line(
		Vector2(-83.0, -184.0),
		Vector2(0.0, -237.0),
		STONE_MID,
		2.0
	)

	draw_line(
		Vector2(0.0, -237.0),
		Vector2(83.0, -184.0),
		STONE_MID,
		2.0
	)

	# ============================================================
	# 9. LARGE CENTRAL WINDOW
	# ============================================================

	_draw_arch_opening(
		Rect2(
			-12.0,
			-188.0,
			24.0,
			92.0
		),
		WINDOW
	)

	# carved frame around it
	draw_line(
		Vector2(-21.0, -95.0),
		Vector2(-21.0, -174.0),
		STONE_LIGHT,
		3.0
	)

	draw_line(
		Vector2(21.0, -95.0),
		Vector2(21.0, -174.0),
		STONE_LIGHT,
		3.0
	)

	# ============================================================
	# 10. LOWER CENTRAL DOOR AND SMALL WINDOWS
	# ============================================================

	_draw_arch_opening(
		Rect2(
			-20.0,
			-66.0,
			40.0,
			66.0
		),
		STONE_SHADOW
	)

	_draw_arch_opening(
		Rect2(
			-59.0,
			-55.0,
			13.0,
			38.0
		),
		WINDOW
	)

	_draw_arch_opening(
		Rect2(
			46.0,
			-55.0,
			13.0,
			38.0
		),
		WINDOW
	)

	# ============================================================
	# 11. LOWER LEFT FACADE ARCH
	# ============================================================

	_draw_arch_opening(
		Rect2(
			-195.0,
			-89.0,
			38.0,
			76.0
		),
		STONE_DARK
	)

	# stone frame
	_draw_arch_outline(
		Rect2(
			-204.0,
			-98.0,
			56.0,
			91.0
		),
		STONE_LIGHT,
		3.0
	)

	# ============================================================
	# 12. LOWER RIGHT FACADE ARCH
	# ============================================================

	_draw_arch_opening(
		Rect2(
			158.0,
			-89.0,
			38.0,
			76.0
		),
		STONE_DARK
	)

	_draw_arch_outline(
		Rect2(
			149.0,
			-98.0,
			56.0,
			91.0
		),
		STONE_LIGHT,
		3.0
	)

	# ============================================================
	# 13. LOWER SIDE BLIND ARCHES
	# ============================================================

	_draw_arch_outline(
		Rect2(
			-245.0,
			-64.0,
			38.0,
			59.0
		),
		STONE_MID,
		2.0
	)

	_draw_arch_outline(
		Rect2(
			207.0,
			-64.0,
			38.0,
			59.0
		),
		STONE_MID,
		2.0
	)

	# ============================================================
	# 14. CENTRAL VERTICAL STONE ARTICULATION
	# ============================================================

	draw_rect(
		Rect2(
			-85.0,
			-182.0,
			7.0,
			182.0
		),
		STONE_MID
	)

	draw_rect(
		Rect2(
			78.0,
			-182.0,
			7.0,
			182.0
		),
		STONE_MID
	)

	# subtle horizontal courses
	for y in [
		-128.0,
		-91.0,
		-51.0
	]:
		draw_line(
			Vector2(-250.0, y),
			Vector2(250.0, y),
			Color(0.36, 0.33, 0.29, 0.28),
			1.0
		)

func _draw_arch_opening(
	rect: Rect2,
	color: Color
) -> void:
	var radius: float = rect.size.x * 0.5
	var center := Vector2(
		rect.position.x + radius,
		rect.position.y + radius
	)

	var points := PackedVector2Array()

	points.append(
		Vector2(
			rect.position.x,
			rect.end.y
		)
	)

	points.append(
		Vector2(
			rect.position.x,
			center.y
		)
	)

	var segments: int = 12

	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = PI + PI * t

		points.append(
			center
			+ Vector2(
				cos(angle),
				sin(angle)
			) * radius
		)

	points.append(
		Vector2(
			rect.end.x,
			rect.end.y
		)
	)

	draw_colored_polygon(
		points,
		color
	)


func _draw_arch_outline(
	rect: Rect2,
	color: Color,
	width: float
) -> void:
	var radius: float = rect.size.x * 0.5

	var center := Vector2(
		rect.position.x + radius,
		rect.position.y + radius
	)

	draw_line(
		Vector2(
			rect.position.x,
			center.y
		),
		Vector2(
			rect.position.x,
			rect.end.y
		),
		color,
		width
	)

	draw_line(
		Vector2(
			rect.end.x,
			center.y
		),
		Vector2(
			rect.end.x,
			rect.end.y
		),
		color,
		width
	)

	draw_arc(
		center,
		radius,
		PI,
		TAU,
		16,
		color,
		width
	)

func _draw_foreground() -> void:
	_draw_tree(
		360.0,
		ground_y - 5.0,
		0.8
	)

	_draw_tree(
		2040.0,
		ground_y - 5.0,
		0.9
	)

	# Low stone foreground wall.
	draw_rect(
		Rect2(
			180.0,
			ground_y - 28.0,
			2040.0,
			28.0
		),
		STONE_MID
	)

	draw_line(
		Vector2(180.0, ground_y - 28.0),
		Vector2(2220.0, ground_y - 28.0),
		STONE_LIGHT,
		2.0
	)


func _draw_tree(
	x: float,
	base_y: float,
	scale_value: float
) -> void:
	draw_rect(
		Rect2(
			x - 5.0 * scale_value,
			base_y - 73.0 * scale_value,
			10.0 * scale_value,
			73.0 * scale_value
		),
		WOOD
	)

	draw_circle(
		Vector2(
			x,
			base_y - 112.0 * scale_value
		),
		45.0 * scale_value,
		TREE_DARK
	)

	draw_circle(
		Vector2(
			x - 23.0 * scale_value,
			base_y - 91.0 * scale_value
		),
		31.0 * scale_value,
		TREE_LIGHT
	)

	draw_circle(
		Vector2(
			x + 25.0 * scale_value,
			base_y - 92.0 * scale_value
		),
		32.0 * scale_value,
		TREE_LIGHT
	)						