extends Node2D
## Zhinvali vertical-route rebuild.
##
## Route graph:
## A River Gate -> B Ladder Junction
## B -> C Pine Switchbacks and B -> D River Descent
## C -> E Shepherds Ridge and C -> F Ruined Watchtower
## D -> Mist Ford -> Dusheti
## E upper -> Ananuri; E lower -> D River Descent
##
## The region stays 2D, but traversal is layered: ladders, ledges,
## switchback slopes, optional upper paths and internal loops.

const BASE_Y: float = 650.0
const REST_SCENE: PackedScene = preload("res://scenes/objects/rest_shrine.tscn")
const WOLF_SCENE: PackedScene = preload("res://scenes/enemies/mountain_wolf.tscn")
const BOAR_SCENE: PackedScene = preload("res://scenes/enemies/wild_boar.tscn")
const RAIDER_SCENE: PackedScene = preload("res://scenes/enemies/zhinvali_raider.tscn")
const HAWK_SCENE: PackedScene = preload("res://scenes/enemies/zhinvali_hawk.tscn")
const ROCKFALL_SCENE: PackedScene = preload("res://scenes/traps/zhinvali_rockfall.tscn")
const SCREE_SCENE: PackedScene = preload("res://scenes/traps/zhinvali_scree.tscn")
const OBJECT_SCENE: PackedScene = preload("res://scenes/objects/zhinvali_interactable.tscn")
const TRAVELLER_SCENE: PackedScene = preload("res://scenes/objects/zhinvali_traveller.tscn")
const HEALING_STONE_SCENE: PackedScene = preload("res://scenes/objects/healing_stone_pickup.tscn")
const LADDER_SCENE: PackedScene = preload("res://scenes/objects/mountain_ladder.tscn")

# 0 A River Gate; 1 B Ladder Junction; 2 C Pine Switchbacks;
# 3 E Shepherds Ridge; 4 D River Descent; 5 Mist Ford;
# 6 F Ruined Watchtower; 7 Ananuri Approach; 8 Dusheti Approach.
@export_range(0, 8, 1) var area_index: int = 0
@export var area_width: float = 5400.0
@export var area_name: String = "Zhinvali - Aragvi River Gate"

const TITLES: Array[String] = [
	"THE RIVER GATE",
	"THE LADDER ROAD",
	"SWITCHBACKS ABOVE THE PINES",
	"THE HIGH SHEPHERDS' RIDGE",
	"THE LOWER ARAGVI ROAD",
	"THE FORD OF SILENCE",
	"THE FORGOTTEN WATCHTOWER",
	"THE OLD ROAD TO ANANURI",
	"THE DESCENT TOWARD DUSHETI"
]

const CLUES: Array[String] = [
	"A traveller spoke of Samdzivari beside the Aragvi. She carried neither a bundle nor a name.",
	"The old ladder reaches the high goat-road. The lower track follows the river under the cliffs.",
	"A broken comb with a woman's hair was found where the pine road bends above the gorge.",
	"The shepherd saw a lone woman follow the far ridge at dawn. She refused his shelter.",
	"An old ferryman remembers a pilgrim who feared to return to her own people.",
	"The river hides what the mountains reveal. Follow the track along the willow bank.",
	"Beneath the ruined watchfire is a scratched name: Samdzivari. Someone passed here alive.",
	"Beyond these stones the mountain road opens toward Ananuri.",
	"The lower road bends toward Dusheti. Every crossroads conceals another story."
]

const CAMERA_TOPS: Array[int] = [-520, -760, -980, -780, -620, -560, -900, -620, -540]

var _player: CharacterBody2D
var _clock: float = 0.0
var _route_segments: Array[Dictionary] = []
var _rock_positions: Array[Vector2] = []
var _tree_positions: Array[Vector2] = []


func _ready() -> void:
	_player = get_node_or_null("Player") as CharacterBody2D
	_build_terrain()
	_build_props()
	_build_rare_healing_stones()
	_build_encounters()
	_build_title()
	if area_index == 1:
		_build_junction_labels()
	_build_wayfinding_labels()

	var world: Node = get_node_or_null("/root/WorldState")
	if world != null and world.has_method("enter_location"):
		var where: String = "zhinvali"
		if area_index == 7:
			where = "ananuri"
		elif area_index == 8:
			where = "dusheti"
		world.call("enter_location", where)
	queue_redraw()


func camera_bounds() -> Rect2i:
	var top: int = CAMERA_TOPS[clampi(area_index, 0, CAMERA_TOPS.size() - 1)]
	return Rect2i(0, top, roundi(area_width), 1280 - top)


func _process(delta: float) -> void:
	_clock += delta
	if int(_clock * 5.0) != int((_clock - delta) * 5.0):
		queue_redraw()

	if not is_instance_valid(_player):
		return
	if _player.global_position.y > maxf(1320.0, _height_at(_player.global_position.x) + 520.0):
		var health: Node = _player.get_node_or_null("HealthComponent")
		if health != null and not bool(health.get("is_dead")):
			health.call("take_damage", 9999)


# -----------------------------------------------------------------------------
# Base mountain road
# -----------------------------------------------------------------------------

func _height_at(x: float) -> float:
	var t: float = clampf(x / maxf(area_width, 1.0), 0.0, 1.0)
	var eased: float = t * t * (3.0 - 2.0 * t)
	match area_index:
		1:
			# B now has two routes at the SAME junction: the high road climbs above,
			# while the lower Aragvi road keeps descending beneath the overhang.
			var lower_t: float = clampf((x - 3300.0) / 2200.0, 0.0, 1.0)
			var lower_eased: float = lower_t * lower_t * (3.0 - 2.0 * lower_t)
			return BASE_Y + 120.0 * lower_eased
		2:
			return 520.0 - 95.0 * eased + sin(t * PI * 3.0) * 8.0
		3:
			return 565.0 - 115.0 * eased
		4:
			return BASE_Y + 155.0 * eased
		5:
			return 705.0 + 48.0 * eased
		6:
			return BASE_Y - 42.0 * eased
		7:
			return BASE_Y - 72.0 * eased
		8:
			return BASE_Y + 58.0 * eased
		_:
			return BASE_Y


func _build_terrain() -> void:
	_build_polygon_ground(0.0, area_width)
	_make_block("WestWall", Vector2(-20.0, 120.0), Vector2(40.0, 3200.0))
	_make_block("EastWall", Vector2(area_width + 20.0, 120.0), Vector2(40.0, 3200.0))

	if area_index == 0:
		_make_block("AragviBridgeDeck", Vector2(2860.0, BASE_Y - 11.0), Vector2(500.0, 24.0))

	_build_vertical_routes()


func _build_polygon_ground(x0: float, x1: float) -> void:
	var body := StaticBody2D.new()
	body.name = "MountainRoadGround"
	body.collision_layer = 1
	body.collision_mask = 1
	var outline := PackedVector2Array()
	var count: int = maxi(2, ceili((x1 - x0) / 44.0))
	for i in range(count + 1):
		var x: float = lerpf(x0, x1, float(i) / float(count))
		outline.append(Vector2(x, _height_at(x)))
	outline.append(Vector2(x1, 1600.0))
	outline.append(Vector2(x0, 1600.0))
	var collision := CollisionPolygon2D.new()
	collision.polygon = outline
	body.add_child(collision)
	add_child(body)


func _make_block(label: String, at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


# All mountain routes are physically curved, not just drawn to look curved.
# The same smooth profile drives collision, visual rock faces, and ladder tops.
# Tower floors remain structural and flat: they are not mountain paths.
func _curve_slope(knots: Array[Vector2], index: int) -> float:
	if index <= 0 or index >= knots.size() - 1:
		return 0.0
	var p: Vector2 = knots[index - 1]
	var q: Vector2 = knots[index]
	var r: Vector2 = knots[index + 1]
	var h0: float = maxf(1.0, q.x - p.x)
	var h1: float = maxf(1.0, r.x - q.x)
	var d0: float = (q.y - p.y) / h0
	var d1: float = (r.y - q.y) / h1
	if d0 * d1 <= 0.0:
		return 0.0
	return clampf((h0 + h1) / (h0 / d0 + h1 / d1), -0.32, 0.32)


func _curve_height(knots: Array[Vector2], x: float) -> float:
	if x <= knots[0].x:
		return knots[0].y
	var last: int = knots.size() - 1
	if x >= knots[last].x:
		return knots[last].y
	for i in range(last):
		var a: Vector2 = knots[i]
		var b: Vector2 = knots[i + 1]
		if x > b.x:
			continue
		var h: float = b.x - a.x
		var t: float = clampf((x - a.x) / maxf(h, 1.0), 0.0, 1.0)
		var t2: float = t * t
		var t3: float = t2 * t
		var m0: float = _curve_slope(knots, i)
		var m1: float = _curve_slope(knots, i + 1)
		return (2.0 * t3 - 3.0 * t2 + 1.0) * a.y + (t3 - 2.0 * t2 + t) * h * m0 + (-2.0 * t3 + 3.0 * t2) * b.y + (t3 - t2) * h * m1
	return knots[last].y


func _route_surface(name: String, x: float) -> float:
	for segment in _route_segments:
		if String(segment["name"]) == name:
			return _curve_height(segment["knots"], x)
	return _height_at(x)


func _sample_route(knots: Array[Vector2], step: float = 26.0, from_x: float = -INF) -> PackedVector2Array:
	var samples := PackedVector2Array()
	var start: float = maxf(knots[0].x, from_x)
	var stop: float = knots[knots.size() - 1].x
	if start >= stop:
		return samples
	var count: int = maxi(2, ceili((stop - start) / step))
	for i in range(count + 1):
		var x: float = lerpf(start, stop, float(i) / float(count))
		samples.append(Vector2(x, _curve_height(knots, x)))
	return samples


func _add_route_curve(label: String, knots: Array[Vector2], thickness: float = 38.0, solid_start: float = -INF, mountain: bool = true) -> void:
	assert(knots.size() >= 2)
	for i in range(1, knots.size()):
		assert(knots[i].x > knots[i - 1].x)
	var all_points: PackedVector2Array = _sample_route(knots)
	var collision_points: PackedVector2Array = _sample_route(knots, 26.0, solid_start)
	_route_segments.append({
		"name": label,
		"knots": knots,
		"samples": all_points,
		"thickness": thickness,
		"mountain": mountain
	})
	if collision_points.size() < 2:
		return
	var body := StaticBody2D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 1
	var polygon := PackedVector2Array()
	for point in collision_points:
		polygon.append(point)
	for i in range(collision_points.size() - 1, -1, -1):
		polygon.append(collision_points[i] + Vector2(0.0, thickness))
	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon
	# Upper mountain trails are pass-through from below, so the B -> D river
	# road remains physically accessible underneath the rock overhang.
	collision.one_way_collision = mountain
	collision.one_way_collision_margin = 5.0
	body.add_child(collision)
	add_child(body)


func _add_route_segment(label: String, x0: float, x1: float, y0: float, y1: float, thickness: float = 38.0) -> void:
	# Reusable only for man-made tower floors. Mountain paths use curves above.
	_add_route_curve(label, [Vector2(x0, y0), Vector2(x1, y1)], thickness, -INF, false)


func _add_ladder(label: String, x: float, bottom_y: float, top_y: float, prompt: bool = true) -> void:
	var ladder := LADDER_SCENE.instantiate() as Area2D
	if ladder == null:
		return
	ladder.name = label
	ladder.position = Vector2(x, bottom_y)
	ladder.set("ladder_height", maxf(80.0, bottom_y - top_y))
	ladder.set("show_prompt", prompt)
	add_child(ladder)


func _build_vertical_routes() -> void:
	match area_index:
		0:
			# River Gate: an overlook grows from the riverbank and returns gently
			# into the earth instead of ending with a vertical cut.
			_add_route_curve("RiverOverlook", [
				Vector2(690.0, _height_at(690.0)), Vector2(960.0, 626.0),
				Vector2(1310.0, 548.0), Vector2(1700.0, 484.0),
				Vector2(2070.0, 460.0), Vector2(2380.0, 456.0),
				Vector2(2640.0, 480.0), Vector2(2980.0, 551.0),
				Vector2(3380.0, _height_at(3380.0)),
				Vector2(3570.0, _height_at(3570.0))
			])
			_add_ladder("OverlookWestLadder", 1320.0, _height_at(1320.0), _route_surface("RiverOverlook", 1320.0))
			_add_ladder("OverlookEastLadder", 2260.0, _height_at(2260.0), _route_surface("RiverOverlook", 2260.0), false)

		1:
			# B keeps its upper mountain lane and lower Aragvi road separate. The
			# single upper road continues beyond the right scene edge toward C.
			_add_route_curve("BUpperMountainRoad", [
				Vector2(2170.0, _height_at(2170.0)),
				Vector2(2530.0, 632.0), Vector2(2930.0, 566.0),
				Vector2(3300.0, 477.0), Vector2(3790.0, 367.0),
				Vector2(4190.0, 325.0), Vector2(4540.0, 278.0),
				Vector2(4930.0, 226.0), Vector2(5410.0, 188.0),
				Vector2(5825.0, 172.0)
			], 42.0, 3040.0)
			_add_ladder("MainBranchLadder", 3200.0, _height_at(3200.0), _route_surface("BUpperMountainRoad", 3200.0))
			_add_ladder("LookoutLadder", 4380.0, _height_at(4380.0), _route_surface("BUpperMountainRoad", 4380.0), false)

		2:
			# Pine Switchbacks: main ascent stays continuous into E. The side
			# branch reaches F on a broad crest, then gradually rejoins the main
			# mountain rather than abruptly stopping in midair.
			_add_route_curve("PineMountainRoad", [
				Vector2(260.0, _height_at(260.0)), Vector2(650.0, 507.0),
				Vector2(1040.0, 450.0), Vector2(1580.0, 372.0),
				Vector2(2180.0, 351.0), Vector2(2760.0, 328.0),
				Vector2(3320.0, 264.0), Vector2(3830.0, 209.0),
				Vector2(4330.0, 178.0), Vector2(5030.0, 145.0),
				Vector2(5650.0, 124.0), Vector2(6280.0, 116.0)
			])
			_add_ladder("PineLadderOne", 940.0, _height_at(940.0), _route_surface("PineMountainRoad", 940.0))
			_add_ladder("PineShortcutLadder", 2920.0, _height_at(2920.0), _route_surface("PineMountainRoad", 2920.0), false)
			_add_route_curve("WatchtowerSideAscent", [
				Vector2(3840.0, _route_surface("PineMountainRoad", 3840.0)),
				Vector2(4150.0, 178.0), Vector2(4530.0, 108.0),
				Vector2(4910.0, 22.0), Vector2(5220.0, -15.0),
				Vector2(5400.0, -12.0), Vector2(5630.0, 12.0),
				Vector2(5970.0, 84.0),
				Vector2(6280.0, _route_surface("PineMountainRoad", 6280.0))
			], 34.0)
			_add_ladder("TowerShelfLadder", 4740.0, _route_surface("PineMountainRoad", 4740.0), _route_surface("WatchtowerSideAscent", 4740.0))

		3:
			# Shepherds Ridge separates the Ananuri high road from the lower route
			# toward D. High cliff continues offscreen; low road remains unobstructed.
			_add_route_curve("ShepherdMountainRoad", [
				Vector2(340.0, _height_at(340.0)), Vector2(780.0, 535.0),
				Vector2(1220.0, 422.0), Vector2(1720.0, 343.0),
				Vector2(2350.0, 323.0), Vector2(2890.0, 284.0),
				Vector2(3470.0, 218.0), Vector2(3840.0, 149.0),
				Vector2(4360.0, 97.0), Vector2(4900.0, 63.0),
				Vector2(5460.0, 48.0), Vector2(5660.0, 47.0)
			], 38.0, 970.0)
			_add_ladder("ShepherdWestLadder", 1160.0, _height_at(1160.0), _route_surface("ShepherdMountainRoad", 1160.0))
			_add_ladder("ShepherdLoopLadder", 2320.0, _height_at(2320.0), _route_surface("ShepherdMountainRoad", 2320.0), false)
			_add_ladder("RidgeSummitLadder", 4250.0, _height_at(4250.0), _route_surface("ShepherdMountainRoad", 4250.0))

		4:
			# River Descent: long upper traverse rolls back down into the riverbank
			# before the Mist Ford exit; no suspended terminal cliff.
			_add_route_curve("AragviHighTraverse", [
				Vector2(1600.0, _height_at(1600.0)), Vector2(1900.0, 672.0),
				Vector2(2300.0, 600.0), Vector2(2760.0, 530.0),
				Vector2(3350.0, 493.0), Vector2(4100.0, 472.0),
				Vector2(4340.0, 463.0), Vector2(4650.0, 510.0),
				Vector2(4950.0, 576.0), Vector2(5250.0, 663.0),
				Vector2(5580.0, 754.0),
				Vector2(5790.0, _height_at(5790.0))
			], 38.0, 2390.0)
			_add_ladder("TraverseWestLadder", 2720.0, _height_at(2720.0), _route_surface("AragviHighTraverse", 2720.0))
			_add_ladder("TraverseEastLadder", 4700.0, _height_at(4700.0), _route_surface("AragviHighTraverse", 4700.0), false)

		5:
			# Mist Ford: broad, low crossing with a smooth rise and return to the
			# same bank, keeping the exterior ruins entrance reachable at ground.
			_add_route_curve("WillowBankSlope", [
				Vector2(520.0, _height_at(520.0)), Vector2(930.0, 692.0),
				Vector2(1400.0, 616.0), Vector2(1810.0, 544.0),
				Vector2(2150.0, 517.0), Vector2(2470.0, 538.0),
				Vector2(2840.0, 646.0), Vector2(3200.0, _height_at(3200.0)),
				Vector2(3540.0, _height_at(3540.0))
			])
			_add_ladder("FordWestLadder", 1360.0, _height_at(1360.0), _route_surface("WillowBankSlope", 1360.0))
			_add_ladder("FordEastLadder", 2240.0, _height_at(2240.0), _route_surface("WillowBankSlope", 2240.0), false)

		6:
			# Watchtower floors are masonry, not mountain slopes. Render their
			# supports and wall joints as real stone, not floating boards.
			_add_route_segment("TowerFloorOne", 1380.0, 2520.0, 462.0, 462.0)
			_add_ladder("TowerLadderOne", 1540.0, _height_at(1540.0), 462.0)
			_add_route_segment("TowerFloorTwo", 1780.0, 2860.0, 286.0, 286.0)
			_add_ladder("TowerLadderTwo", 2360.0, 462.0, 286.0)
			_add_route_segment("TowerCrown", 2080.0, 3200.0, 112.0, 100.0)
			_add_ladder("TowerLadderThree", 2720.0, 286.0, 108.0)

		7:
			# Ananuri: the terrace grows out of the road, passes wooden retaining
			# braces, and descends gradually back into the approach instead of
			# abruptly ending halfway across the level.
			_add_route_curve("AnanuriTerracedSlope", [
				Vector2(710.0, _height_at(710.0)), Vector2(1110.0, 595.0),
				Vector2(1540.0, 508.0), Vector2(1980.0, 442.0),
				Vector2(2500.0, 417.0), Vector2(3060.0, 412.0),
				Vector2(3320.0, 432.0), Vector2(3620.0, 477.0),
				Vector2(3890.0, 537.0), Vector2(4130.0, _height_at(4130.0)),
				Vector2(4250.0, _height_at(4250.0))
			])
			_add_ladder("AnanuriTerraceLadder", 1900.0, _height_at(1900.0), _route_surface("AnanuriTerracedSlope", 1900.0), false)

		8:
			# Dusheti: the lookout rolls into a gentle return slope, then blends
			# back into the plain before the rest of the village road.
			_add_route_curve("DushetiRollingLookout", [
				Vector2(450.0, _height_at(450.0)), Vector2(770.0, 644.0),
				Vector2(1190.0, 546.0), Vector2(1650.0, 505.0),
				Vector2(2260.0, 488.0), Vector2(2550.0, 513.0),
				Vector2(2910.0, 594.0), Vector2(3310.0, _height_at(3310.0)),
				Vector2(3570.0, _height_at(3570.0))
			])
			_add_ladder("DushetiLookoutWest", 1390.0, _height_at(1390.0), _route_surface("DushetiRollingLookout", 1390.0), false)
			_add_ladder("DushetiLookoutEast", 2140.0, _height_at(2140.0), _route_surface("DushetiRollingLookout", 2140.0), false)


# -----------------------------------------------------------------------------
# Props, clues and NPCs
# -----------------------------------------------------------------------------

func _build_props() -> void:
	if area_index == 0:
		var shrine := REST_SCENE.instantiate() as Node2D
		shrine.name = "FirstZhinvaliRest"
		shrine.position = Vector2(460.0, _height_at(460.0))
		shrine.set("spawn_id", "zhinvali_first_rest")
		add_child(shrine)

		var marker := Marker2D.new()
		marker.name = "FirstZhinvaliRestSpawn"
		marker.position = Vector2(460.0, _height_at(460.0) - 48.0)
		marker.set_script(preload("res://scripts/levels/mtskheta/spawn_point.gd"))
		marker.set("spawn_id", "zhinvali_first_rest")
		add_child(marker)

	var cfg: Array = []
	match area_index:
		0:
			cfg = [
				[1240.0, "spring", "A cold mountain spring washes the dust from your wounds."],
				[4210.0, "inscription", CLUES[0]]
			]
		1:
			cfg = [
				[1400.0, "milestone", CLUES[1]]
			]
		2:
			cfg = [
				[1760.0, "milestone", CLUES[2], 356.0],
				[4140.0, "spring", "Clear mountain water gathers beneath the upper switchback.", 184.0]
			]
		3:
			cfg = [
				[1540.0, "camp", "A shepherd shares bread and remembers a traveller going north.", 334.0]
			]
		4:
			cfg = [
				[1240.0, "spring", "Water seeps from a rock cleft. Drink and recover."]
			]
		5:
			cfg = [
				[1600.0, "milestone", CLUES[5], 520.0],
				[3670.0, "spring", "The ford's clear pools are safe to drink."]
			]
		6:
			cfg = [
				[2180.0, "cache", "A hidden supply bundle lies beneath the broken tower floor.", 108.0]
			]
		7:
			cfg = [
				[1800.0, "camp", "A watchman's fire is still warm.", 446.0],
				[3280.0, "milestone", CLUES[7]]
			]
		8:
			cfg = [
				[1360.0, "spring", "The lower road is watered by a limestone source.", 500.0],
				[3210.0, "milestone", CLUES[8]]
			]

	for i in range(cfg.size()):
		var item: Array = cfg[i]
		var x: float = float(item[0])
		var y: float = float(item[3]) if item.size() > 3 else _height_at(x)
		var obj := OBJECT_SCENE.instantiate() as Node2D
		obj.name = "MountainObject_%02d" % i
		obj.position = Vector2(x, y)
		obj.set("kind", String(item[1]))
		obj.set("message", String(item[2]))
		add_child(obj)

	var traveller_specs: Array = []
	match area_index:
		0:
			traveller_specs = [[910.0, _height_at(910.0), "River Pilgrim", [
				"You are far from Mtskheta, Xizane.",
				"Near the old ford, I saw a lone woman on the northern path.",
				"The mountain road divides beyond the river gate."
			]]]
		1:
			traveller_specs = [[1110.0, BASE_Y, "Road Keeper", [
				"The ladder is the old northern road now. The slope below it failed years ago.",
				"Climb and the goat-road will take you toward Ananuri.",
				"Stay low and the river track bends toward Dusheti."
			]]]
		3:
			traveller_specs = [[2020.0, 330.0, "Mountain Shepherd", [
				"A girl crossed this ridge before sunrise.",
				"She asked which road went deepest into the mountains.",
				"She did not turn back."
			]]]
		5:
			traveller_specs = [[3390.0, _height_at(3390.0), "Aragvi Ferryman", [
				"The ford is calm now, but stones come down without warning.",
				"I remember a traveller who would not speak her village's name.",
				"The road into Dusheti may carry news of her."
			]]]

	for spec in traveller_specs:
		var person := TRAVELLER_SCENE.instantiate() as Node2D
		person.name = "LocalTraveller"
		person.position = Vector2(float(spec[0]), float(spec[1]))
		person.set("speaker_name", String(spec[2]))
		person.set("dialogue", PackedStringArray(spec[3]))
		add_child(person)


func _build_rare_healing_stones() -> void:
	var specs: Array = []
	match area_index:
		2:
			specs = [[4980.0, -28.0, "zhinvali_switchbacks_01"]]
		5:
			specs = [[4080.0, _height_at(4080.0), "zhinvali_mist_ford_01"]]
		_:
			specs = []

	for spec in specs:
		var stone := HEALING_STONE_SCENE.instantiate() as Area2D
		if stone == null:
			continue
		stone.name = "HealingStone"
		stone.position = Vector2(float(spec[0]), float(spec[1]) - 6.0)
		stone.set("pickup_id", String(spec[2]))
		add_child(stone)


# -----------------------------------------------------------------------------
# Encounters and traps
# -----------------------------------------------------------------------------

func _build_encounters() -> void:
	_spawn_enemy_wave()
	_spawn_traps()


func _encounter_specs() -> Array:
	match area_index:
		0:
			return [
				[1950.0, "boar", _height_at(1950.0)],
				[1870.0, "raider", 462.0],
				[3870.0, "hawk", _height_at(3870.0)]
			]
		1:
			return [
				[1820.0, "wolf", BASE_Y],
				[4300.0, "raider", 284.0],
				[5050.0, "hawk", 222.0]
			]
		2:
			return [
				[1640.0, "wolf", 356.0],
				[3220.0, "raider", 246.0],
				[4250.0, "hawk", 182.0]
			]
		3:
			return [
				[1730.0, "wolf", 332.0],
				[2990.0, "hawk", 268.0],
				[4300.0, "raider", 74.0]
			]
		4:
			return [
				[1900.0, "boar", _height_at(1900.0)],
				[3540.0, "raider", 491.0],
				[4860.0, "wolf", _height_at(4860.0)]
			]
		5:
			return [
				[1680.0, "hawk", 520.0],
				[2860.0, "raider", _height_at(2860.0)]
			]
		6:
			return [
				[1180.0, "wolf", _height_at(1180.0)],
				[2280.0, "raider", 286.0],
				[2960.0, "hawk", 104.0]
			]
		7:
			return [[2380.0, "raider", 430.0], [3420.0, "wolf", _height_at(3420.0)]]
		8:
			return [[2160.0, "boar", 490.0]]
	return []


func _trap_specs() -> Array:
	match area_index:
		0:
			return [[3470.0, "rockfall", _height_at(3470.0)]]
		1:
			return [[2260.0, "scree", BASE_Y], [3860.0, "rockfall", 320.0]]
		2:
			return [[2680.0, "rockfall", 300.0], [3940.0, "scree", 192.0]]
		3:
			return [[2860.0, "rockfall", 280.0]]
		4:
			return [[2940.0, "scree", _height_at(2940.0)], [4550.0, "rockfall", 458.0]]
		5:
			return [[2350.0, "rockfall", _height_at(2350.0)], [3560.0, "scree", _height_at(3560.0)]]
		6:
			return [[2140.0, "scree", 286.0], [3080.0, "rockfall", 104.0]]
	return []


func _spawn_enemy_wave() -> void:
	for spec in _encounter_specs():
		_spawn_enemy(spec)


func _spawn_enemy(spec: Array) -> void:
	var x: float = float(spec[0])
	var kind: String = String(spec[1])
	var surface_y: float = float(spec[2]) if spec.size() > 2 else _height_at(x)
	var enemy: Node2D = null
	match kind:
		"wolf":
			enemy = WOLF_SCENE.instantiate() as Node2D
		"boar":
			enemy = BOAR_SCENE.instantiate() as Node2D
		"hawk":
			enemy = HAWK_SCENE.instantiate() as Node2D
		"raider":
			enemy = RAIDER_SCENE.instantiate() as Node2D

	if enemy == null:
		return
	enemy.position = Vector2(x, surface_y - (165.0 if kind == "hawk" else 31.0))
	enemy.add_to_group("zhinvali_enemy")
	add_child(enemy)


func _spawn_traps() -> void:
	for spec in _trap_specs():
		var hazard: Node2D = null
		if String(spec[1]) == "rockfall":
			hazard = ROCKFALL_SCENE.instantiate() as Node2D
		else:
			hazard = SCREE_SCENE.instantiate() as Node2D
		if hazard != null:
			hazard.position = Vector2(float(spec[0]), float(spec[2]))
			add_child(hazard)


## Called by the rest shrine. Defeated enemies return to their authored positions.
func respawn_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("zhinvali_enemy"):
		if is_instance_valid(enemy) and is_ancestor_of(enemy):
			enemy.queue_free()
	for projectile in get_tree().get_nodes_in_group("zhinvali_enemy_projectile"):
		if is_instance_valid(projectile) and is_ancestor_of(projectile):
			projectile.queue_free()
	call_deferred("_spawn_enemy_wave")


# -----------------------------------------------------------------------------
# UI and world labels
# -----------------------------------------------------------------------------

func _build_title() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var title := Label.new()
	title.text = area_name.to_upper() + "\n" + TITLES[area_index]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -360.0
	title.offset_right = 360.0
	title.offset_top = 54.0
	title.offset_bottom = 138.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#f4e5c7"))
	title.add_theme_color_override("font_outline_color", Color("#25332d"))
	title.add_theme_constant_override("outline_size", 5)
	layer.add_child(title)
	var fade := create_tween()
	fade.tween_interval(3.0)
	fade.tween_property(title, "modulate:a", 0.0, 0.8)
	fade.tween_callback(layer.queue_free)


func _build_junction_labels() -> void:
	# Road names are now attached directly to their wooden signboards.
	pass


func _build_wayfinding_labels() -> void:
	var specs: Array = []
	match area_index:
		1:
			specs = [
				[3820.0, 344.0, "ANANURI", true],
				[4920.0, _height_at(4920.0), "MIST FORD", true]
			]
		2:
			specs = [[4300.0, 214.0, "WATCHTOWER", true]]
		3:
			specs = [
				[4360.0, 172.0, "ANANURI", true],
				[5050.0, _height_at(5050.0), "RIVER DESCENT", false]
			]
		4:
			specs = [[4010.0, _height_at(4010.0), "MIST FORD", true]]
		5:
			specs = [
				[1810.0, _height_at(1810.0), "FORD RUINS", false],
				[4250.0, _height_at(4250.0), "DUSHETI", true]
			]
		6:
			specs = [[2930.0, 206.0, "SWITCHBACKS", false]]
		7:
			specs = [[3570.0, 472.0, "ANANURI", true]]
		8:
			specs = [[3320.0, _height_at(3320.0), "DUSHETI", true]]
	for spec in specs:
		_add_sign_label(float(spec[0]), float(spec[1]), String(spec[2]), bool(spec[3]))


func _add_sign_label(x: float, y: float, word: String, right: bool) -> void:
	var label := Label.new()
	label.text = word
	label.size = Vector2(150.0, 32.0)
	if right:
		label.position = Vector2(x - 84.0, y - 121.0)
	else:
		label.position = Vector2(x - 66.0, y - 121.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.rotation = deg_to_rad(-1.4 if right else 1.4)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("#3d2c1d"))
	label.add_theme_color_override("font_outline_color", Color("#a88459", 0.34))
	label.add_theme_constant_override("outline_size", 1)
	add_child(label)


# -----------------------------------------------------------------------------
# Procedural silhouette art
# -----------------------------------------------------------------------------

func _draw() -> void:
	_draw_sky()
	_draw_far_ridges()
	_draw_cedar_trees()
	_draw_landmarks()
	_draw_vertical_route_surfaces()
	_draw_road()
	if area_index == 7:
		_draw_ananuri_timber()
	_draw_stones()
	_draw_zhinvali_route_scenery_v16()
	if area_index == 1:
		_draw_sign(4920.0, _height_at(4920.0), "MIST FORD", true)
		_draw_sign(3820.0, 344.0, "ANANURI", true)
	elif area_index == 2:
		_draw_sign(4300.0, 214.0, "WATCHTOWER", true)
	elif area_index == 3:
		_draw_sign(4360.0, 172.0, "ANANURI", true)
		_draw_sign(5050.0, _height_at(5050.0), "RIVER DESCENT", false)
	elif area_index == 4:
		_draw_sign(4010.0, _height_at(4010.0), "MIST FORD", true)
	elif area_index == 5:
		_draw_sign(1810.0, _height_at(1810.0), "FORD RUINS", false)
		_draw_sign(4250.0, _height_at(4250.0), "DUSHETI", true)
	elif area_index == 6:
		_draw_sign(2930.0, 206.0, "SWITCHBACKS", false)
	elif area_index == 7:
		_draw_sign(3570.0, 472.0, "ANANURI", true)
	elif area_index == 8:
		_draw_sign(3320.0, _height_at(3320.0), "DUSHETI", true)


func _draw_sky() -> void:
	for i in range(24):
		var t: float = float(i) / 23.0
		var top_col := Color("#eadfc7")
		var low_col := Color("#c0c0aa")
		if area_index == 1:
			top_col = Color("#e0d7c4")
			low_col = Color("#b6bbaa")
		elif area_index == 2:
			top_col = Color("#d3d9cc")
			low_col = Color("#adb8a7")
		elif area_index in [4, 5, 8]:
			top_col = Color("#d5cfc0")
			low_col = Color("#adae9f")
		draw_rect(Rect2(0.0, -1750.0 + float(i) * 125.0, area_width, 126.0), top_col.lerp(low_col, t))
	draw_circle(Vector2(area_width * 0.72, -270.0), 92.0, Color("#f6e6b9", 0.22))


func _draw_far_ridges() -> void:
	for layer in range(3):
		var points := PackedVector2Array()
		var colors: Array[Color] = [Color("#b4b49d"), Color("#90957e"), Color("#6e7666")]
		if area_index == 1:
			colors = [Color("#c4bba8"), Color("#9fa18e"), Color("#747d6f")]
		elif area_index == 2:
			colors = [Color("#b5bcb1"), Color("#8d9e90"), Color("#65796c")]
		var ridge_color: Color = colors[layer]
		var samples: int = int(area_width / 70.0) + 2
		for i in range(samples):
			var x: float = minf(float(i) * 70.0, area_width)
			var base: float = 110.0 + float(layer) * 145.0
			var y: float = base + sin(x / (620.0 - 110.0 * float(layer)) + float(layer) * 1.7) * 62.0
			if area_index in [2, 3, 6]:
				y -= 120.0
			points.append(Vector2(x, y))
		points.append(Vector2(area_width, 1600.0))
		points.append(Vector2(0.0, 1600.0))
		draw_colored_polygon(points, ridge_color)

	if area_index in [0, 4, 5, 8]:
		var river := PackedVector2Array([
			Vector2(0.0, 552.0), Vector2(area_width * 0.27, 518.0),
			Vector2(area_width * 0.53, 560.0), Vector2(area_width, 582.0),
			Vector2(area_width, 609.0), Vector2(0.0, 590.0)
		])
		draw_colored_polygon(river, Color("#819790", 0.58))
		for i in range(14):
			var x: float = 90.0 + float(i) * (area_width - 180.0) / 14.0
			draw_line(Vector2(x, 563.0 + sin(x / 390.0) * 9.0), Vector2(x + 94.0, 566.0 + sin(x / 390.0) * 9.0), Color("#e0dfcf", 0.28), 2.0)


func _draw_cedar_trees() -> void:
	for pos in _tree_positions:
		var x: float = pos.x
		var y: float = pos.y
		var height: float = 110.0 + float((int(x) / 140) % 4) * 17.0
		draw_line(Vector2(x, y), Vector2(x - 4.0, y - height), Color("#484139"), 7.0)
		for tier in range(3):
			var ty: float = y - height + float(tier) * 25.0
			var breadth: float = 45.0 - float(tier) * 7.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 4.0, ty - 29.0),
				Vector2(x - breadth, ty + 29.0),
				Vector2(x + breadth, ty + 29.0)
			]), Color("#50624e", 0.94) if tier % 2 == 0 else Color("#65785d", 0.92))


func _draw_road() -> void:
	var polygon := PackedVector2Array()
	var count: int = maxi(4, ceili(area_width / 44.0))
	for i in range(count + 1):
		var x: float = area_width * float(i) / float(count)
		polygon.append(Vector2(x, _height_at(x)))
	polygon.append(Vector2(area_width, 1600.0))
	polygon.append(Vector2(0.0, 1600.0))
	draw_colored_polygon(polygon, Color("#6d6353"))

	for i in range(count):
		var x: float = area_width * float(i) / float(count)
		var nx: float = area_width * float(i + 1) / float(count)
		draw_line(Vector2(x, _height_at(x)), Vector2(nx, _height_at(nx)), Color("#c9b18b"), 7.0, true)
		draw_line(Vector2(x, _height_at(x) + 17.0), Vector2(nx, _height_at(nx) + 17.0), Color("#908a73"), 2.0, true)




func _draw_vertical_route_surfaces() -> void:
	# Cliff mass, shadows, collision ribbon and highlighted dirt all follow the
	# exact same smooth curve. No straight pieces or pasted-on triangular ramps.
	# First draw the rock masses, then ALL path caps, so a second slope never
	# hides the walkable surface of the lower one.

	for segment in _route_segments:
		var points: PackedVector2Array = segment["samples"]
		if points.size() < 2:
			continue
		var thick: float = float(segment["thickness"])
		if not bool(segment["mountain"]):
			continue
		var rock := PackedVector2Array()
		for j in range(points.size()):
			var p: Vector2 = points[j]
			var ground_delta: float = _height_at(p.x) - p.y
			var depth_blend: float = clampf((ground_delta - 2.0) / 64.0, 0.0, 1.0)
			rock.append(p + Vector2(0.0, 3.0 + 5.0 * depth_blend))
		for i in range(points.size() - 1, -1, -1):
			var q: Vector2 = points[i]
			var ground_delta: float = _height_at(q.x) - q.y
			var join_blend: float = clampf(ground_delta / 75.0, 0.0, 1.0)
			rock.append(Vector2(q.x, lerpf(q.y + 5.0, maxf(_height_at(q.x) + 12.0, q.y + thick + 42.0), join_blend)))
		draw_colored_polygon(rock, Color("#5c584c", 0.98))

		var shadow := PackedVector2Array()
		for p in points:
			var base_y: float = maxf(_height_at(p.x) + 12.0, p.y + thick + 42.0)
			var join_blend: float = clampf((_height_at(p.x) - p.y) / 75.0, 0.0, 1.0)
			shadow.append(Vector2(p.x, lerpf(p.y + 5.0, lerpf(p.y + thick, base_y, 0.28), join_blend)))
		for i in range(points.size() - 1, -1, -1):
			var q: Vector2 = points[i]
			var join_blend: float = clampf((_height_at(q.x) - q.y) / 75.0, 0.0, 1.0)
			shadow.append(Vector2(q.x, lerpf(q.y + 5.0, maxf(_height_at(q.x) + 12.0, q.y + thick + 42.0), join_blend)))
		draw_colored_polygon(shadow, Color("#48453d", 0.45))

		# Fine, irregular rock planes, no repeated green shelf bottoms.
		for i in range(6, points.size() - 4, 8):
			var point: Vector2 = points[i]
			var base_y: float = maxf(_height_at(point.x) - 4.0, point.y + thick + 20.0)
			if base_y - point.y < 56.0:
				continue
			var frac: float = 0.40 + 0.13 * sin(float(i) * 1.79)
			draw_line(
				point + Vector2(0.0, thick + 20.0),
				Vector2(point.x - 21.0 + float(i % 4) * 11.0, lerpf(point.y + thick + 18.0, base_y, frac)),
				Color("#39372f", 0.28), 2.0
			)

	# The watchtower's three walkable floors are supported by surviving masonry.
	# Keep their structural shapes distinct from the mountain approach paths.
	if area_index == 6:
		for column_spec in [
			[1700.0, 462.0, 590.0], [2380.0, 462.0, 590.0],
			[1900.0, 286.0, 456.0], [2715.0, 286.0, 456.0],
			[2210.0, 110.0, 282.0], [2990.0, 104.0, 282.0]
		]:
			var xx: float = float(column_spec[0])
			var yy: float = float(column_spec[1])
			var bottom: float = float(column_spec[2])
			draw_rect(Rect2(xx - 18.0, yy + 20.0, 36.0, maxf(0.0, bottom - yy - 20.0)), Color("#5b5347", 0.88))
			draw_rect(Rect2(xx - 23.0, yy + 16.0, 46.0, 12.0), Color("#8c7b65", 0.86))
			draw_line(Vector2(xx - 10.0, yy + 35.0), Vector2(xx - 10.0, bottom - 8.0), Color("#a29076", 0.28), 2.0)

	for segment in _route_segments:
		var points: PackedVector2Array = segment["samples"]
		if points.size() < 2:
			continue
		var thick: float = float(segment["thickness"])
		var surface := PackedVector2Array()
		for p in points:
			surface.append(p)
		for i in range(points.size() - 1, -1, -1):
			surface.append(points[i] + Vector2(0.0, thick))
		if bool(segment["mountain"]):
			draw_colored_polygon(surface, Color("#81705a", 0.98))
		else:
			draw_colored_polygon(surface, Color("#6e6658", 0.98))
		for i in range(points.size() - 1):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var cap_col: Color = Color("#c9b18b") if bool(segment["mountain"]) else Color("#96856b")
			draw_line(a, b, cap_col, 3.0, true)
			draw_line(a + Vector2(0.0, 12.0), b + Vector2(0.0, 12.0), Color("#a18c70", 0.65), 1.2, true)


# ZHINVALI_ROUTE_SCENERY_V16_BEGIN
# Decorative scenery only. Samples the existing curved surfaces; never changes
# collision bodies, route knots, ladders, transitions, enemies or interactables.
func _draw_zhinvali_route_scenery_v16() -> void:
	if area_index != 1 and area_index != 2:
		return

	_draw_zhinvali_cliff_detail_v16()

	var main_route: String = "BUpperMountainRoad" if area_index == 1 else "PineMountainRoad"
	# x, height, foliage variant, route name (optional). Keep the travel lane readable.
	var pines: Array = []
	var shrubs: Array = []
	var loose_stones: Array = []
	if area_index == 1:
		pines = [
			[3510.0, 122.0, 0], [4100.0, 146.0, 1],
			[4700.0, 114.0, 2], [5240.0, 132.0, 0]
		]
		shrubs = [
			[3380.0, 0.85, 0], [3670.0, 1.05, 1], [4390.0, 0.92, 2],
			[4900.0, 1.10, 0], [5450.0, 0.83, 1]
		]
		loose_stones = [
			[3580.0, 14.0, 0], [3890.0, 19.0, 1], [4290.0, 13.0, 2],
			[4610.0, 20.0, 0], [5020.0, 15.0, 1], [5380.0, 18.0, 2]
		]
	else:
		pines = [
			[1310.0, 138.0, 1], [1940.0, 156.0, 0],
			[2580.0, 126.0, 2], [3460.0, 164.0, 1],
			[4130.0, 123.0, 0], [5570.0, 148.0, 2],
			[4900.0, 108.0, 1, "WatchtowerSideAscent"]
		]
		shrubs = [
			[1090.0, 1.10, 0], [1640.0, 0.78, 1], [2320.0, 0.94, 2],
			[3080.0, 1.04, 0], [3730.0, 0.86, 1], [4440.0, 1.18, 2],
			[5360.0, 0.88, 0], [5700.0, 0.72, 1, "WatchtowerSideAscent"]
		]
		loose_stones = [
			[1460.0, 14.0, 1], [1810.0, 19.0, 0], [2190.0, 17.0, 2],
			[2890.0, 13.0, 1], [3270.0, 21.0, 0], [3800.0, 15.0, 2],
			[4630.0, 18.0, 1], [5260.0, 16.0, 2],
			[5520.0, 13.0, 0, "WatchtowerSideAscent"]
		]

	# Stones go first so shrubs and tree trunks grow visibly from the same soil.
	for item in loose_stones:
		var road_name: String = String(item[3]) if item.size() > 3 else main_route
		var x: float = float(item[0])
		var y: float = _route_surface(road_name, x)
		_draw_zhinvali_stone_v16(Vector2(x, y), float(item[1]), int(item[2]), false)
	for item in shrubs:
		var road_name: String = String(item[3]) if item.size() > 3 else main_route
		var x: float = float(item[0])
		_draw_zhinvali_shrub_v16(Vector2(x, _route_surface(road_name, x)), float(item[1]), int(item[2]))
	for item in pines:
		var road_name: String = String(item[3]) if item.size() > 3 else main_route
		var x: float = float(item[0])
		_draw_zhinvali_pine_v16(Vector2(x, _route_surface(road_name, x)), float(item[1]), int(item[2]))


func _draw_zhinvali_cliff_detail_v16() -> void:
	# The lower boundary is either the valley ground or the MAIN road under
	# the watchtower spur. Nothing is drawn across the lower walkable road.
	var strata: Array = []
	if area_index == 1:
		strata = [["BUpperMountainRoad", "", 3190.0, 5520.0]]
	else:
		strata = [
			["PineMountainRoad", "", 1060.0, 5990.0],
			["WatchtowerSideAscent", "PineMountainRoad", 4520.0, 5880.0]
		]
	var stones: Array[Color] = [
		Color("#817562"), Color("#6d756d"), Color("#91826b"),
		Color("#555f5a"), Color("#756b5d")
	]
	if area_index == 2:
		stones = [
			Color("#7b8078"), Color("#747768"), Color("#91836c"),
			Color("#53655f"), Color("#8a7c69")
		]

	for spec in strata:
		var upper_name: String = String(spec[0])
		var under_name: String = String(spec[1])
		var first_x: float = float(spec[2])
		var last_x: float = minf(float(spec[3]), area_width - 70.0)
		var count: int = maxi(1, floori((last_x - first_x) / 205.0))
		for i in range(count + 1):
			var x: float = first_x + float(i) * 205.0
			if x > last_x:
				continue
			var top_y: float = _route_surface(upper_name, x)
			var bottom_y: float = _height_at(x) if under_name.is_empty() else _route_surface(under_name, x)
			var gap: float = bottom_y - top_y
			if gap < 105.0:
				continue
			# Fragmented rock planes embedded in the slope; unlike platform slabs,
			# these use irregular heights, mineral tones and translucent edges.
			var face_top: float = top_y + maxf(31.0, gap * 0.19)
			var face_low: float = top_y + minf(gap - 30.0, gap * (0.64 + float(i % 3) * 0.045))
			var reach: float = 52.0 + float((i * 13) % 4) * 10.0
			var facet := PackedVector2Array([
				Vector2(x - reach, face_top + 19.0),
				Vector2(x - 19.0, face_top - 12.0),
				Vector2(x + reach * 0.35, face_top + 4.0),
				Vector2(x + reach, face_low - 24.0),
				Vector2(x + 10.0, face_low + 8.0),
				Vector2(x - reach * 0.62, face_low - 13.0)
			])
			var facet_color: Color = stones[i % stones.size()]
			facet_color.a = 0.48
			draw_colored_polygon(facet, facet_color)
			draw_line(Vector2(x - reach + 5.0, face_top + 22.0), Vector2(x - 16.0, face_top - 8.0), Color("#d2baa0", 0.18), 1.7)
			draw_line(Vector2(x + reach * 0.38, face_top + 7.0), Vector2(x + reach - 5.0, face_low - 22.0), Color("#292e2d", 0.32), 1.7)
			# Distant scree stones on the cliff, deliberately dimmer than path stones.
			var scree_y: float = top_y + gap * 0.82
			if scree_y < bottom_y - 19.0:
				_draw_zhinvali_stone_v16(Vector2(x + 31.0, scree_y), 9.0 + float(i % 4) * 2.6, (i + 2) % 3, true)
			if gap > 185.0:
				_draw_zhinvali_stone_v16(Vector2(x - 52.0, top_y + gap * 0.52), 7.0 + float(i % 3) * 2.0, i % 3, true)


func _draw_zhinvali_stone_v16(at: Vector2, radius: float, variant: int, distant: bool) -> void:
	var shade: Array[Color] = [Color("#766f62"), Color("#7c8079"), Color("#97846c")]
	var dark: Array[Color] = [Color("#4f4c44"), Color("#4f5b55"), Color("#64594c")]
	var light: Array[Color] = [Color("#b1a18b"), Color("#a6aaa0"), Color("#c3aa88")]
	var k: int = posmod(variant, 3)
	var alpha: float = 0.58 if distant else 0.97
	var p: PackedVector2Array = PackedVector2Array([
		at + Vector2(-radius * 1.15, 0.0),
		at + Vector2(-radius * 0.75, -radius * 0.88),
		at + Vector2(-radius * 0.16, -radius * 1.28),
		at + Vector2(radius * 0.64, -radius * 1.05),
		at + Vector2(radius * 1.10, -radius * 0.30),
		at + Vector2(radius * 1.04, 0.0)
	])
	var dark_color: Color = dark[k]
	dark_color.a = alpha
	draw_colored_polygon(p, dark_color)
	draw_colored_polygon(PackedVector2Array([
		p[0], p[1], p[2], at + Vector2(radius * 0.06, -radius * 0.18)
	]), _zhinvali_alpha_v16(shade[k], alpha))
	draw_colored_polygon(PackedVector2Array([
		p[2], p[3], p[4], at + Vector2(radius * 0.06, -radius * 0.18)
	]), _zhinvali_alpha_v16(light[k], alpha * 0.52))
	draw_line(p[1], p[2], Color("#d8c5a8", alpha * 0.38), 1.25)


func _draw_zhinvali_shrub_v16(at: Vector2, size: float, variant: int) -> void:
	var clumps: Array[Color] = [Color("#6e7654"), Color("#828369"), Color("#68776d")]
	if area_index == 2:
		clumps = [Color("#627360"), Color("#7c816a"), Color("#586d67")]
	var tint: Color = clumps[posmod(variant, clumps.size())]
	var r: float = 23.0 * size
	# Several asymmetrical twig silhouettes beneath compact angular foliage.
	for i in range(4):
		var ox: float = (float(i) - 1.5) * r * 0.37
		draw_line(at + Vector2(ox * 0.3, -1.0), at + Vector2(ox, -r * (0.72 + float(i % 2) * 0.26)), Color("#554c3d", 0.80), 2.0)
	for i in range(3):
		var off: float = (float(i) - 1.0) * r * 0.61
		var tip: Vector2 = at + Vector2(off, -r * (1.3 + float((i + variant) % 2) * 0.25))
		draw_colored_polygon(PackedVector2Array([
			at + Vector2(off - r * 0.83, -r * 0.10),
			at + Vector2(off - r * 0.51, -r * 0.80),
			tip,
			at + Vector2(off + r * 0.55, -r * 0.68),
			at + Vector2(off + r * 0.83, -r * 0.10)
		]), _zhinvali_alpha_v16(tint, 0.91 - float(i) * 0.07))
		draw_line(tip + Vector2(-r * 0.14, r * 0.18), tip + Vector2(-r * 0.26, r * 0.40), Color("#b0a786", 0.20), 1.1)


func _draw_zhinvali_pine_v16(at: Vector2, height: float, variant: int) -> void:
	var shadow_colors: Array[Color] = [Color("#3d514a"), Color("#4b5c51"), Color("#4e6154")]
	var lit_colors: Array[Color] = [Color("#60705d"), Color("#6c7762"), Color("#73816a")]
	if area_index == 2:
		shadow_colors = [Color("#344f4c"), Color("#435e56"), Color("#476359")]
		lit_colors = [Color("#5b7367"), Color("#657d6c"), Color("#6d806e")]
	var k: int = posmod(variant, 3)
	var crown: Vector2 = at + Vector2(-height * 0.036, -height)
	draw_line(at, crown, Color("#544c40"), 5.0)
	for i in range(4):
		var t: float = float(i) / 4.0
		var tip_y: float = crown.y + height * t * 0.18
		var half: float = (21.0 + float(i) * 11.0) * (height / 135.0)
		var bottom: float = crown.y + height * (0.36 + t * 0.61)
		var center: float = at.x - height * 0.036 + height * t * 0.030
		var branch := PackedVector2Array([
			Vector2(center, tip_y),
			Vector2(center - half * 0.45, bottom - height * 0.10),
			Vector2(center - half, bottom),
			Vector2(center - half * 0.12, bottom - height * 0.045),
			Vector2(center + half, bottom),
			Vector2(center + half * 0.48, bottom - height * 0.12)
		])
		draw_colored_polygon(branch, _zhinvali_alpha_v16(shadow_colors[k], 0.98))
		draw_line(Vector2(center, tip_y + 2.0), Vector2(center - half * 0.48, bottom - height * 0.09), _zhinvali_alpha_v16(lit_colors[k], 0.35), 2.2)
	# Small exposed roots meet the curved walking surface rather than hovering.
	draw_line(at + Vector2(-10.0, 0.0), at + Vector2(0.0, -6.0), Color("#655947", 0.72), 1.7)
	draw_line(at + Vector2(0.0, -6.0), at + Vector2(10.0, 0.0), Color("#655947", 0.72), 1.7)


func _zhinvali_alpha_v16(color: Color, alpha: float) -> Color:
	var tint: Color = color
	tint.a = alpha
	return tint
# ZHINVALI_ROUTE_SCENERY_V16_END


func _draw_stones() -> void:
	for pos in _rock_positions:
		var x: float = pos.x
		var y: float = pos.y
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 19.0, y), Vector2(x - 12.0, y - 16.0),
			Vector2(x + 6.0, y - 24.0), Vector2(x + 23.0, y - 4.0), Vector2(x + 25.0, y)
		]), Color("#7d7768"))
		draw_line(Vector2(x - 12.0, y - 14.0), Vector2(x + 8.0, y - 19.0), Color("#b9ad8d"), 1.8)


func _draw_landmarks() -> void:
	match area_index:
		0:
			# Old river bridge silhouette.
			draw_rect(Rect2(2610.0, BASE_Y - 35.0, 500.0, 23.0), Color("#796b59"))
			for x in [2680.0, 2860.0, 3040.0]:
				draw_rect(Rect2(x - 12.0, BASE_Y - 18.0, 24.0, 120.0), Color("#655e52"))
		3:
			# Shepherd shelter on the middle shelf.
			draw_rect(Rect2(1880.0, 270.0, 180.0, 64.0), Color("#665746"))
			draw_colored_polygon(PackedVector2Array([
				Vector2(1850.0, 270.0), Vector2(1970.0, 214.0), Vector2(2090.0, 270.0)
			]), Color("#4b453b"))
		5:
			# Broken ford ruins: surviving cut-stone piers, collapsed paving and a taller
			# watch-ford tower on the bank that the player can enter.
			draw_colored_polygon(PackedVector2Array([
				Vector2(1280.0, 640.0), Vector2(1395.0, 548.0), Vector2(1540.0, 522.0),
				Vector2(1700.0, 548.0), Vector2(1830.0, 640.0)
			]), Color("#6c6558", 0.68))
			for x in [1460.0, 1605.0, 1755.0]:
				draw_rect(Rect2(x - 22.0, 516.0, 44.0, 124.0), Color("#73695c", 0.84))
				draw_rect(Rect2(x - 14.0, 540.0, 28.0, 98.0), Color("#91826f", 0.28))
			for xx in [1420.0, 1490.0, 1560.0, 1640.0, 1720.0, 1800.0]:
				draw_colored_polygon(PackedVector2Array([
					Vector2(xx - 24.0, 640.0), Vector2(xx - 10.0, 614.0), Vector2(xx + 13.0, 608.0), Vector2(xx + 30.0, 640.0)
				]), Color("#8f816e", 0.84))
			# Watch-ford tower shell.
			draw_colored_polygon(PackedVector2Array([
				Vector2(2120.0, 640.0), Vector2(2120.0, 318.0), Vector2(2200.0, 272.0),
				Vector2(2270.0, 292.0), Vector2(2340.0, 246.0), Vector2(2430.0, 282.0),
				Vector2(2510.0, 228.0), Vector2(2615.0, 270.0), Vector2(2700.0, 246.0),
				Vector2(2795.0, 302.0), Vector2(2795.0, 640.0)
			]), Color("#675f52", 0.90))
			draw_colored_polygon(PackedVector2Array([
				Vector2(2190.0, 640.0), Vector2(2190.0, 344.0), Vector2(2435.0, 302.0),
				Vector2(2718.0, 336.0), Vector2(2718.0, 640.0)
			]), Color("#4a433a", 0.48))
			# Door arch and windows.
			draw_colored_polygon(PackedVector2Array([
				Vector2(2358.0, 640.0), Vector2(2358.0, 540.0), Vector2(2420.0, 490.0),
				Vector2(2482.0, 540.0), Vector2(2482.0, 640.0)
			]), Color("#23201c", 0.96))
			draw_arc(Vector2(2420.0, 542.0), 62.0, PI, TAU, 16, Color("#9a8a72", 0.62), 4.0)
			for rect in [Rect2(2244.0, 426.0, 34.0, 72.0), Rect2(2576.0, 412.0, 36.0, 78.0), Rect2(2398.0, 360.0, 44.0, 68.0)]:
				draw_rect(rect, Color("#312d28", 0.76))
			# Broken crown / battlements.
			for poly in [
				PackedVector2Array([Vector2(2160.0, 320.0), Vector2(2212.0, 246.0), Vector2(2260.0, 320.0)]),
				PackedVector2Array([Vector2(2304.0, 286.0), Vector2(2360.0, 214.0), Vector2(2418.0, 286.0)]),
				PackedVector2Array([Vector2(2474.0, 286.0), Vector2(2536.0, 204.0), Vector2(2594.0, 286.0)]),
				PackedVector2Array([Vector2(2638.0, 290.0), Vector2(2698.0, 232.0), Vector2(2758.0, 290.0)])
			]:
				draw_colored_polygon(poly, Color("#5d5649", 0.96))
			# Rubble and tower foot stones.
			for x in [2195.0, 2260.0, 2315.0, 2620.0, 2688.0, 2742.0]:
				draw_colored_polygon(PackedVector2Array([
					Vector2(x - 20.0, 640.0), Vector2(x - 8.0, 618.0), Vector2(x + 16.0, 610.0), Vector2(x + 24.0, 640.0)
				]), Color("#887a67", 0.86))

		6:
			# A substantial ruined watchtower shell with a visible doorway, broken crown
			# and interior openings behind the climbable floors. It should read as a place
			# the player actually enters rather than a flat rectangle.
			draw_colored_polygon(PackedVector2Array([
				Vector2(1540.0, 594.0), Vector2(1540.0, 152.0), Vector2(1715.0, 112.0),
				Vector2(1840.0, 148.0), Vector2(1970.0, 98.0), Vector2(2140.0, 142.0),
				Vector2(2280.0, 120.0), Vector2(2410.0, 168.0), Vector2(2520.0, 116.0),
				Vector2(2680.0, 152.0), Vector2(2830.0, 136.0), Vector2(2990.0, 188.0),
				Vector2(3080.0, 594.0)
			]), Color("#665d4d", 0.84))
			draw_colored_polygon(PackedVector2Array([
				Vector2(1605.0, 594.0), Vector2(1605.0, 180.0), Vector2(1810.0, 148.0),
				Vector2(2020.0, 156.0), Vector2(2220.0, 136.0), Vector2(2460.0, 168.0),
				Vector2(2710.0, 178.0), Vector2(3010.0, 212.0), Vector2(3010.0, 594.0)
			]), Color("#4f483d", 0.56))
			# Doorway and inner shadow.
			draw_colored_polygon(PackedVector2Array([
				Vector2(1930.0, 594.0), Vector2(1930.0, 430.0), Vector2(2015.0, 362.0),
				Vector2(2100.0, 430.0), Vector2(2100.0, 594.0)
			]), Color("#2b2824", 0.95))
			draw_arc(Vector2(2015.0, 430.0), 85.0, PI, TAU, 18, Color("#8d7d61", 0.54), 4.0)
			# Floors and broken openings.
			for rect in [
				Rect2(1680.0, 446.0, 1160.0, 18.0),
				Rect2(1780.0, 270.0, 1080.0, 18.0),
				Rect2(2090.0, 96.0, 1110.0, 18.0)
			]:
				draw_rect(rect, Color("#796b59", 0.86))
			for xx in [1710.0, 1870.0, 2230.0, 2390.0, 2710.0]:
				draw_rect(Rect2(xx, 232.0, 72.0, 88.0), Color("#312d28", 0.74))
			for xx in [1760.0, 2090.0, 2410.0, 2730.0]:
				draw_rect(Rect2(xx, 400.0, 66.0, 82.0), Color("#36322c", 0.70))
			# Broken crown silhouette.
			for poly in [
				PackedVector2Array([Vector2(1580.0, 150.0), Vector2(1670.0, 88.0), Vector2(1755.0, 150.0)]),
				PackedVector2Array([Vector2(1845.0, 150.0), Vector2(1940.0, 70.0), Vector2(2040.0, 150.0)]),
				PackedVector2Array([Vector2(2150.0, 150.0), Vector2(2245.0, 94.0), Vector2(2335.0, 150.0)]),
				PackedVector2Array([Vector2(2465.0, 150.0), Vector2(2575.0, 80.0), Vector2(2675.0, 150.0)]),
				PackedVector2Array([Vector2(2775.0, 150.0), Vector2(2870.0, 110.0), Vector2(2975.0, 150.0)])
			]:
				draw_colored_polygon(poly, Color("#5f5648", 0.92))
			# Rubble around the entrance.
			for x in [1760.0, 1840.0, 1890.0, 2190.0, 2310.0, 2460.0, 2860.0]:
				draw_colored_polygon(PackedVector2Array([
					Vector2(x - 18.0, 594.0), Vector2(x - 7.0, 573.0),
					Vector2(x + 14.0, 565.0), Vector2(x + 22.0, 594.0)
				]), Color("#877963", 0.84))
		7:
			# Old Ananuri wall line: warm-grey stone with weathered timber retaining
			# logs across the lower slope and a few fallen beams in the foreground.
			draw_rect(Rect2(3480.0, 360.0, 420.0, 115.0), Color("#6e6757", 0.70))
			draw_rect(Rect2(3540.0, 280.0, 72.0, 194.0), Color("#625c50", 0.76))
			draw_rect(Rect2(3790.0, 315.0, 65.0, 160.0), Color("#625c50", 0.76))




func _draw_ananuri_timber() -> void:
	for j in range(5):
		var xx: float = 1890.0 + float(j) * 216.0
		var y: float = _route_surface("AnanuriTerracedSlope", xx) + 26.0
		# Buried uprights and multiple uneven tree-trunk courses.
		draw_line(Vector2(xx, y + 5.0), Vector2(xx - 5.0, y + 81.0), Color("#40372e", 0.88), 11.0)
		draw_line(Vector2(xx - 14.0, y + 17.0), Vector2(xx + 153.0, _route_surface("AnanuriTerracedSlope", xx + 153.0) + 36.0), Color("#654a33", 0.94), 14.0, true)
		draw_line(Vector2(xx - 14.0, y + 19.0), Vector2(xx + 153.0, _route_surface("AnanuriTerracedSlope", xx + 153.0) + 39.0), Color("#a0835e", 0.50), 3.0, true)
	for xx in [1300.0, 3070.0, 4100.0]:
		var yy: float = _height_at(xx)
		draw_line(Vector2(xx - 48.0, yy - 4.0), Vector2(xx + 55.0, yy - 8.0), Color("#654a34", 0.93), 20.0, true)
		draw_line(Vector2(xx - 42.0, yy - 11.0), Vector2(xx + 48.0, yy - 15.0), Color("#b29572", 0.43), 2.0, true)

func _draw_sign(x: float, y: float, word: String, right: bool) -> void:
	draw_rect(Rect2(x - 5.0, y - 111.0, 10.0, 111.0), Color("#594838"))
	var board: PackedVector2Array
	if right:
		board = PackedVector2Array([
			Vector2(x - 88.0, y - 125.0), Vector2(x + 70.0, y - 125.0),
			Vector2(x + 101.0, y - 108.0), Vector2(x + 70.0, y - 91.0),
			Vector2(x - 88.0, y - 91.0)
		])
	else:
		board = PackedVector2Array([
			Vector2(x + 88.0, y - 125.0), Vector2(x - 70.0, y - 125.0),
			Vector2(x - 101.0, y - 108.0), Vector2(x - 70.0, y - 91.0),
			Vector2(x + 88.0, y - 91.0)
		])
	draw_colored_polygon(board, Color("#70543d"))
	# Physical sign lettering is echoed by a world Label; these scratches keep
	# the silhouette readable even when the label is outside the camera.
	var marks: int = mini(8, word.length())
	for i in range(marks):
		var xx: float = x - 46.0 + float(i) * 12.0
		draw_line(Vector2(xx, y - 114.0), Vector2(xx + 5.0, y - 103.0), Color("#4c3521", 0.58), 1.2)
