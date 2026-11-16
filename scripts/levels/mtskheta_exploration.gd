
extends Node2D

## Playable Mtskheta level extension.
##
## Adds walkable ground, stone terraces, wooden
## platforms and decorative architecture.
##
## Does not modify existing player, wolf or story nodes.

@export_group("Level Dimensions")
@export var ground_y: float = 650.0
@export var existing_ground_end_x: float = 1200.0
@export var level_end_x: float = 3600.0

@export_group("Appearance")
@export var stone_color: Color = Color("#79766d")
@export var stone_edge_color: Color = Color("#b1a38b")
@export var wood_color: Color = Color("#65513c")
@export var earth_color: Color = Color("#51483c")

var _platforms: Array[Rect2] = []
var _wooden_platforms: Array[Rect2] = []

var _ground_rect: Rect2


func _ready() -> void:
	z_index = -5

	_build_ground()
	_build_terraces()
	_build_wooden_walkways()

	queue_redraw()


func _build_ground() -> void:
	var start_x: float = existing_ground_end_x
	var width: float = level_end_x - start_x

	if width <= 0.0:
		push_warning(
			"MtskhetaExploration: invalid ground dimensions"
		)
		return

	_ground_rect = Rect2(
		start_x,
		ground_y,
		width,
		140.0
	)

	_create_solid(
		"ExtendedGround",
		_ground_rect
	)


func _build_terraces() -> void:
	# Stone ledges along the residential district.
	_add_platform(
		"StoneTerrace01",
		1510.0,
		590.0,
		160.0,
		false
	)

	_add_platform(
		"StoneTerrace02",
		1740.0,
		530.0,
		180.0,
		false
	)

	_add_platform(
		"StoneTerrace03",
		1990.0,
		580.0,
		180.0,
		false
	)

	_add_platform(
		"StoneTerrace04",
		2310.0,
		545.0,
		190.0,
		false
	)


func _build_wooden_walkways() -> void:
	# Elevated walkways in the outskirts.
	_add_platform(
		"WoodenWalkway01",
		2620.0,
		570.0,
		190.0,
		true
	)

	_add_platform(
		"WoodenWalkway02",
		2890.0,
		515.0,
		170.0,
		true
	)

	_add_platform(
		"WoodenWalkway03",
		3160.0,
		565.0,
		190.0,
		true
	)


func _add_platform(
	node_name: String,
	center_x: float,
	top_y: float,
	width: float,
	is_wooden: bool
) -> void:
	var rect := Rect2(
		center_x - width * 0.5,
		top_y,
		width,
		16.0
	)

	if is_wooden:
		_wooden_platforms.append(rect)
	else:
		_platforms.append(rect)

	_create_solid(node_name, rect, true)


func _create_solid(
	node_name: String,
	rect: Rect2,
	one_way: bool = false
) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 1

	add_child(body)

	body.position = rect.position + rect.size * 0.5

	var shape := RectangleShape2D.new()
	shape.size = rect.size

	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = shape
	collision_shape.one_way_collision = one_way
	collision_shape.one_way_collision_margin = 1.0

	body.add_child(collision_shape)


func _draw() -> void:
	_draw_ground()
	_draw_stone_platforms()
	_draw_wooden_platforms()
	_draw_town_gate()
	_draw_road_markers()


func _draw_ground() -> void:
	if _ground_rect.size.x <= 0.0:
		return

	draw_rect(_ground_rect, earth_color)

	draw_rect(
		Rect2(
			_ground_rect.position.x,
			ground_y,
			_ground_rect.size.x,
			12.0
		),
		stone_color
	)

	draw_line(
		Vector2(_ground_rect.position.x, ground_y),
		Vector2(level_end_x, ground_y),
		stone_edge_color,
		2.0
	)


func _draw_stone_platforms() -> void:
	for rect: Rect2 in _platforms:
		draw_rect(rect, stone_color)

		draw_rect(
			Rect2(
				rect.position.x,
				rect.position.y,
				rect.size.x,
				4.0
			),
			stone_edge_color
		)

		# Stone joints.
		var joint_x: float = rect.position.x + 25.0

		while joint_x < rect.end.x:
			draw_line(
				Vector2(joint_x, rect.position.y + 5.0),
				Vector2(joint_x, rect.end.y),
				Color("#514f49"),
				1.0
			)

			joint_x += 40.0


func _draw_wooden_platforms() -> void:
	for rect: Rect2 in _wooden_platforms:
		draw_rect(rect, wood_color)

		draw_line(
			Vector2(rect.position.x, rect.position.y),
			Vector2(rect.end.x, rect.position.y),
			Color("#b49a72"),
			2.0
		)

		# Plank divisions.
		var plank_x: float = rect.position.x + 20.0

		while plank_x < rect.end.x:
			draw_line(
				Vector2(plank_x, rect.position.y),
				Vector2(plank_x, rect.end.y),
				Color("#3c3026"),
				1.0
			)

			plank_x += 28.0

		# Decorative supports.
		for support_x in [
			rect.position.x + 15.0,
			rect.end.x - 15.0
		]:
			draw_line(
				Vector2(support_x, rect.end.y),
				Vector2(support_x, ground_y),
				Color("#554735"),
				7.0
			)


func _draw_town_gate() -> void:
	var x: float = 3440.0
	var base_y: float = ground_y

	# Gate pillars.
	draw_rect(
		Rect2(x - 75.0, base_y - 175.0, 35.0, 175.0),
		stone_color
	)

	draw_rect(
		Rect2(x + 40.0, base_y - 175.0, 35.0, 175.0),
		stone_color
	)

	# Overhead lintel.
	draw_rect(
		Rect2(x - 90.0, base_y - 190.0, 180.0, 30.0),
		stone_color
	)

	# Wooden arch interior.
	draw_rect(
		Rect2(x - 39.0, base_y - 150.0, 78.0, 150.0),
		Color("#443b33")
	)

	# Passage opening.
	draw_rect(
		Rect2(x - 31.0, base_y - 145.0, 62.0, 145.0),
		Color("#69746d")
	)


func _draw_road_markers() -> void:
	var x: float = existing_ground_end_x + 40.0

	while x < level_end_x:
		draw_line(
			Vector2(x, ground_y + 24.0),
			Vector2(x + 32.0, ground_y + 29.0),
			Color("#675e50"),
			1.0
		)

		x += 90.0
