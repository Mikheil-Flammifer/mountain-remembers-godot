extends Node2D
## Zhinvali: two navigable roads with real collision slopes and a playable fork.
## Procedural geometry respects Xizane's 96px capsule and the existing travel system.

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

# 0 River Gate; 1 Fork; 2 Switchbacks; 3 Ridge; 4 River Descent;
# 5 Mist Ford; 6 Ruined Watchtower; 7 Ananuri Approach; 8 Dusheti Approach.
@export_range(0, 8, 1) var area_index: int = 0
@export var area_width: float = 5400.0
@export var area_name: String = "Zhinvali - Aragvi River Gate"

const TITLES: Array[String] = [
	"THE RIVER REMEMBERS", "WHERE TWO ROADS PART", "BENEATH THE PINES",
	"THE SHEPHERDS' HIGH RIDGE", "THE LOWER ARAGVI ROAD",
	"THE FORD OF SILENCE", "THE FORGOTTEN WATCHTOWER",
	"THE OLD ROAD TO ANANURI", "THE DESCENT TOWARD DUSHETI"
]
const CLUES: Array[String] = [
	"A traveller spoke of Samdzivari beside the Aragvi. She carried neither a bundle nor a name.",
	"Upward, the high road is watched. Downward, river-folk keep their own counsel.",
	"On the steep path, a broken comb with a woman's hair was found among pine roots.",
	"The shepherd saw a lone woman follow the far ridge at dawn. She refused his shelter.",
	"An old ferryman remembers a pilgrim who feared to return to her own people.",
	"The river hides what the mountains reveal. Follow the track along the willow bank.",
	"Beneath the ruined watchfire is a scratched name: Samdzivari. Someone passed here alive.",
	"Beyond these stones lies the older road watched by the guardians of the Aragvi.",
	"The lower road bends toward Dusheti. Every crossroads conceals another story."
]

var _player: CharacterBody2D
var _clock: float = 0.0
var _road_parts: Array[Vector2] = []
var _rock_positions: Array[Vector2] = []
var _tree_positions: Array[Vector2] = []

func _ready() -> void:
	_player = get_node_or_null("Player") as CharacterBody2D
	_build_terrain()
	_build_props()
	_build_rare_healing_stones()
	if area_index == 1:
		_build_fork_sign_labels()
	_build_encounters()
	_build_title()
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
	var top: int = floori(minf(_height_at(area_width), BASE_Y) - 800.0)
	return Rect2i(0, top, roundi(area_width), 1060 - top)

func _process(delta: float) -> void:
	_clock += delta
	if area_index in [0, 1, 3, 5, 7, 8]:
		# A gentle environmental pulse on water / prayer flags, no per-frame redraw of stone textures.
		if int(_clock * 6.0) != int((_clock - delta) * 6.0):
			queue_redraw()
	if not is_instance_valid(_player):
		return
	if _player.global_position.y > maxf(1250.0, _height_at(_player.global_position.x) + 460.0):
		var health: Node = _player.get_node_or_null("HealthComponent")
		if health != null and not bool(health.get("is_dead")):
			health.call("take_damage", 9999)

# Monotone and smoothly easing terrain profiles: no impassable vertical walls.
func _height_at(x: float) -> float:
	var t: float = clampf(x / maxf(area_width, 1.0), 0.0, 1.0)
	var eased: float = t * t * (3.0 - 2.0 * t)
	match area_index:
		2:
			return BASE_Y - 740.0 * eased + 6.0 * sin(t * PI * 4.0) * sin(PI * t)
		3:
			return BASE_Y - 315.0 * eased
		4:
			return BASE_Y + 178.0 * eased
		5:
			return BASE_Y + 105.0 * eased
		6:
			return BASE_Y - 58.0 * eased
		7:
			return BASE_Y - 55.0 * eased
		8:
			return BASE_Y + 64.0 * eased
	return BASE_Y

func _fork_upper_y(x: float) -> float:
	var t: float = clampf((x - 2760.0) / 1270.0, 0.0, 1.0)
	return BASE_Y - 214.0 * t

func _build_terrain() -> void:
	_road_parts.append(Vector2(0.0, area_width))
	_build_polygon_ground(0.0, area_width)
	_make_block("WestWall", Vector2(-20.0, 150.0), Vector2(40.0, 2900.0))
	_make_block("EastWall", Vector2(area_width + 20.0, 150.0), Vector2(40.0, 2900.0))
	if area_index == 1:
		# Walkable branch: the high road physically rises 214px over 1270px.
		var road := StaticBody2D.new()
		road.name = "UpperRoadFork"
		road.collision_layer = 1
		road.collision_mask = 1
		var collision := CollisionPolygon2D.new()
		collision.polygon = PackedVector2Array([
			Vector2(2760.0, BASE_Y - 4.0),
			Vector2(4030.0, BASE_Y - 218.0),
			Vector2(4030.0, BASE_Y - 173.0),
			Vector2(2760.0, BASE_Y + 39.0)
		])
		road.add_child(collision)
		add_child(road)
	# A rebuilt historic stone bridge at the beginning; collision is real and safe.
	if area_index == 0:
		_make_block("AragviBridgeDeck", Vector2(2880.0, BASE_Y - 11.0), Vector2(490.0, 24.0))

func _build_polygon_ground(x0: float, x1: float) -> void:
	var body := StaticBody2D.new()
	body.name = "MountainRoadGround"
	body.collision_layer = 1
	body.collision_mask = 1
	var outline := PackedVector2Array()
	var n: int = maxi(2, ceili((x1 - x0) / 44.0))
	for i in range(n + 1):
		var x: float = lerpf(x0, x1, float(i) / float(n))
		outline.append(Vector2(x, _height_at(x)))
	outline.append(Vector2(x1, 1580.0))
	outline.append(Vector2(x0, 1580.0))
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

func _build_props() -> void:
	# Beginning checkpoint is a true healing and respawn shrine.
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
	# Environmental storytellers and useful mountain objects.
	var cfg: Array = []
	match area_index:
		0:
			cfg = [[1240, "spring", "A cold mountain spring washes the dust from your wounds."], [4210, "inscription", CLUES[0]]]
		1:
			cfg = [[1350, "milestone", CLUES[1]], [4940, "inscription", "The watchtower below the cedars has stood abandoned for years."]]
		2:
			cfg = [[1960, "milestone", CLUES[2]], [4250, "spring", "Clear mountain water restores your strength."]]
		3:
			cfg = [[1540, "camp", "A shepherd shares bread and remembers a traveller going north."], [3880, "inscription", CLUES[3]]]
		4:
			cfg = [[1240, "spring", "Water seeps from a rock cleft. Drink and recover."], [4050, "inscription", CLUES[4]]]
		5:
			cfg = [[1600, "milestone", CLUES[5]], [3670, "spring", "The ford's clear pools are safe to drink."]]
		6:
			cfg = [[2040, "cache", "A hidden supply bundle: herbs and dry bread."], [3480, "inscription", CLUES[6]]]
		7:
			cfg = [[1800, "camp", "A watchman's fire is still warm."], [3280, "milestone", CLUES[7]]]
		8:
			cfg = [[1360, "spring", "The lower road is watered by a limestone source."], [3210, "milestone", CLUES[8]]]
	for i in range(cfg.size()):
		var item: Array = cfg[i]
		var x: float = float(item[0])
		var obj := OBJECT_SCENE.instantiate() as Node2D
		obj.name = "MountainObject_%02d" % i
		obj.position = Vector2(x, _height_at(x))
		obj.set("kind", String(item[1]))
		obj.set("message", String(item[2]))
		add_child(obj)
	# Friendly NPC conversations about Samdzivari, without triggering rest poses.
	var traveller_specs: Array = []
	match area_index:
		0:
			traveller_specs = [[910, "River Pilgrim", ["You are far from Mtskheta, Xizane.", "Near the old ford, I saw a lone woman on the northern path.", "You may find answers at the three-road fork."]]]
		1:
			traveller_specs = [[1090, "Road Keeper", ["The high road climbs toward Ananuri's watch hill.", "The lower road turns for Dusheti; beware the loose stones.", "There is an older tower hidden beyond the crossroads."]]]
		3:
			traveller_specs = [[2610, "Mountain Shepherd", ["My sheep heard wolves last night near the ridge.", "A girl crossed here, travelling without a companion.", "She asked only which path entered the deepest mountains."]]]
		5:
			traveller_specs = [[3390, "Aragvi Ferryman", ["The ford is calm now, but stones come down without warning.", "I remember a traveller who would not speak her village's name.", "The road into Dusheti may carry news of her."]]]
	for spec in traveller_specs:
		var x: float = float(spec[0])
		var person := TRAVELLER_SCENE.instantiate() as Node2D
		person.name = "LocalTraveller"
		person.position = Vector2(x, _height_at(x))
		person.set("speaker_name", String(spec[1]))
		person.set("dialogue", PackedStringArray(spec[2]))
		add_child(person)
	# Trail props: fallen trees, stone cairns, patches of heather.
	for i in range(int(area_width / 420.0)):
		var x: float = 185.0 + float(i) * 420.0
		if x < 650.0 and area_index == 0:
			continue
		_tree_positions.append(Vector2(x, _height_at(x)))
	for i in range(int(area_width / 240.0)):
		var x: float = 155.0 + float(i) * 240.0
		_rock_positions.append(Vector2(x, _height_at(x)))

func _build_rare_healing_stones() -> void:
	# Intentionally sparse: one on each principal road plus one optional tower stone.
	# They are session-persistent and do not refill at shrines.
	var specs: Array = []
	match area_index:
		2:
			specs = [[4680.0, "zhinvali_switchbacks_01"]]
		5:
			specs = [[4080.0, "zhinvali_mist_ford_01"]]
		6:
			specs = [[3320.0, "zhinvali_ruined_tower_01"]]
		_:
			specs = []

	for spec in specs:
		var x: float = float(spec[0])
		var stone := HEALING_STONE_SCENE.instantiate() as Area2D
		if stone == null:
			continue
		stone.name = "HealingStone"
		stone.position = Vector2(x, _height_at(x) - 6.0)
		stone.set("pickup_id", String(spec[1]))
		add_child(stone)


func _build_encounters() -> void:
	_spawn_enemy_wave()
	_spawn_traps()


func _encounter_specs() -> Array:
	match area_index:
		0:
			return [[1970, "boar"], [3850, "raider"]]
		1:
			return [[1750, "raider"]]
		2:
			return [[1850, "wolf"], [3610, "raider"], [5100, "hawk"]]
		3:
			return [[1720, "hawk"], [3370, "wolf"]]
		4:
			return [[2050, "boar"], [3610, "raider"], [4900, "wolf"]]
		5:
			return [[1620, "hawk"], [2810, "raider"]]
		6:
			return [[1730, "wolf"], [2850, "raider"]]
		7:
			return [[2350, "raider"]]
		8:
			return [[2150, "boar"]]
	return []


func _trap_specs() -> Array:
	match area_index:
		0:
			return [[3470, "rockfall"]]
		1:
			return [[1970, "scree"]]
		2:
			return [[2980, "rockfall"], [4460, "scree"]]
		3:
			return [[2820, "rockfall"]]
		4:
			return [[2940, "scree"], [4530, "rockfall"]]
		5:
			return [[2350, "rockfall"], [3560, "scree"]]
		6:
			return [[2150, "scree"], [3620, "rockfall"]]
	return []


func _spawn_enemy_wave() -> void:
	for spec in _encounter_specs():
		_spawn_enemy(spec)


func _spawn_enemy(spec: Array) -> void:
	var x: float = float(spec[0])
	var kind: String = String(spec[1])
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

	enemy.position = Vector2(x, _height_at(x) - (165.0 if kind == "hawk" else 31.0))
	enemy.add_to_group("zhinvali_enemy")
	add_child(enemy)


func _spawn_traps() -> void:
	for spec in _trap_specs():
		var x: float = float(spec[0])
		var hazard: Node2D = null
		if String(spec[1]) == "rockfall":
			hazard = ROCKFALL_SCENE.instantiate() as Node2D
		else:
			hazard = SCREE_SCENE.instantiate() as Node2D

		if hazard != null:
			hazard.position = Vector2(x, _height_at(x))
			add_child(hazard)


## Called by the rest shrine. Existing enemies disappear and the authored
## encounter wave returns at its original positions, Dark-Souls-style.
func respawn_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("zhinvali_enemy"):
		if is_instance_valid(enemy) and is_ancestor_of(enemy):
			enemy.queue_free()
	for projectile in get_tree().get_nodes_in_group("zhinvali_enemy_projectile"):
		if is_instance_valid(projectile) and is_ancestor_of(projectile):
			projectile.queue_free()
	call_deferred("_spawn_enemy_wave")


func _build_title() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var title := Label.new()
	title.text = area_name.to_upper() + "\n" + TITLES[area_index]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -340.0
	title.offset_right = 340.0
	title.offset_top = 56.0
	title.offset_bottom = 136.0
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

func _build_fork_sign_labels() -> void:
	var labels: Array = [
		[2330.0, BASE_Y - 118.0, "DUSHETI  v"],
		[3150.0, _fork_upper_y(3150.0) - 118.0, "ANANURI  ^"],
		[4790.0, BASE_Y - 118.0, "OLD TOWER  >"]
	]
	for spec in labels:
		var label := Label.new()
		label.text = String(spec[2])
		label.position = Vector2(float(spec[0]) - 88.0, float(spec[1]) + 2.0)
		label.size = Vector2(184.0, 29.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("#f5dfae"))
		label.add_theme_color_override("font_outline_color", Color("#3c322b"))
		label.add_theme_constant_override("outline_size", 3)
		add_child(label)

func _draw() -> void:
	_draw_sky()
	_draw_far_ridges()
	_draw_cedar_trees()
	_draw_landmarks()
	_draw_road()
	_draw_stones()
	if area_index == 1:
		_draw_branch_ramp()

func _draw_sky() -> void:
	for i in range(23):
		var t: float = float(i) / 22.0
		var top_col := Color("#e6dfc7")
		var low_col := Color("#b8c5af")
		if area_index in [4, 5, 8]:
			top_col = Color("#cbd2c6")
			low_col = Color("#9faea6")
		draw_rect(Rect2(0.0, -1600.0 + float(i) * 115.0, area_width, 116.0), top_col.lerp(low_col, t))
	draw_circle(Vector2(area_width * 0.72, -240.0), 92.0, Color("#f7ebbf", 0.24))

func _draw_far_ridges() -> void:
	for layer in range(3):
		var points := PackedVector2Array()
		var color: Color = [Color("#a7b8a2"), Color("#839a85"), Color("#607b6d")][layer]
		for i in range(int(area_width / 60.0) + 2):
			var x: float = minf(float(i) * 60.0, area_width)
			var base: float = _height_at(x) - 440.0 + float(layer) * 143.0
			var y: float = base + sin(x / (600.0 - 120.0 * float(layer)) + float(layer) * 1.9) * 52.0
			points.append(Vector2(x, y))
		points.append(Vector2(area_width, 1580.0))
		points.append(Vector2(0.0, 1580.0))
		draw_colored_polygon(points, color)
	# A distant pine-covered valley, not the 20th-century reservoir.
	if area_index in [0, 4, 5]:
		var river := PackedVector2Array([
			Vector2(0.0, 548.0), Vector2(area_width * 0.27, 510.0),
			Vector2(area_width * 0.53, 555.0), Vector2(area_width, 576.0),
			Vector2(area_width, 598.0), Vector2(0.0, 585.0)
		])
		draw_colored_polygon(river, Color("#7c9d9a", 0.55))
		for i in range(15):
			var x: float = 90.0 + float(i) * (area_width - 180.0) / 15.0
			draw_line(Vector2(x, 556.0 + sin(x / 400.0) * 10.0), Vector2(x + 95.0, 561.0 + sin(x / 400.0) * 10.0), Color("#d9e5d5", 0.30), 2.0)

func _draw_cedar_trees() -> void:
	for pos in _tree_positions:
		var x: float = pos.x
		var y: float = pos.y
		var height: float = 105.0 + float((int(x) / 140) % 4) * 17.0
		draw_line(Vector2(x, y), Vector2(x - 5.0, y - height), Color("#403e35"), 7.0)
		for tier in range(3):
			var ty: float = y - height + float(tier) * 24.0
			var breadth: float = 44.0 - float(tier) * 7.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 5.0, ty - 28.0), Vector2(x - breadth, ty + 28.0),
				Vector2(x + breadth, ty + 28.0)
			]), Color("#455e4d", 0.94) if tier % 2 == 0 else Color("#587762", 0.92))

func _draw_road() -> void:
	var polygon := PackedVector2Array()
	var count: int = maxi(4, ceili(area_width / 44.0))
	for i in range(count + 1):
		var x: float = area_width * float(i) / float(count)
		polygon.append(Vector2(x, _height_at(x)))
	polygon.append(Vector2(area_width, 1590.0))
	polygon.append(Vector2(0.0, 1590.0))
	draw_colored_polygon(polygon, Color("#645f4f"))
	for i in range(count):
		var x: float = area_width * float(i) / float(count)
		var nx: float = area_width * float(i + 1) / float(count)
		draw_line(Vector2(x, _height_at(x)), Vector2(nx, _height_at(nx)), Color("#c1af8c"), 7.0, true)
		draw_line(Vector2(x, _height_at(x) + 17.0), Vector2(nx, _height_at(nx) + 17.0), Color("#8b9277"), 2.0, true)
	for i in range(int(area_width / 90.0)):
		var x: float = 25.0 + float(i) * 90.0
		var y: float = _height_at(x)
		draw_line(Vector2(x, y + 47.0), Vector2(x + 65.0, _height_at(x + 65.0) + 46.0), Color("#4a5149", 0.48), 1.6)
		var x_joint: float = x + 32.0
		draw_line(Vector2(x_joint, y + 18.0), Vector2(x_joint, y + 44.0), Color("#8e8a6e", 0.48), 1.1)

func _draw_stones() -> void:
	for pos in _rock_positions:
		var x: float = pos.x
		var y: float = pos.y
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 19.0, y), Vector2(x - 12.0, y - 16.0),
			Vector2(x + 6.0, y - 24.0), Vector2(x + 23.0, y - 4.0), Vector2(x + 25.0, y)
		]), Color("#747566"))
		draw_line(Vector2(x - 12.0, y - 14.0), Vector2(x + 8.0, y - 19.0), Color("#b0ac91"), 1.8)
		for branch in range(3):
			var xx: float = x + 37.0 + float(branch) * 13.0
			draw_line(Vector2(xx, y), Vector2(xx - 6.0, y - 13.0), Color("#7b8b65"), 1.8)

func _draw_branch_ramp() -> void:
	var bank := PackedVector2Array()
	for i in range(30):
		var x: float = 2760.0 + float(i) * 1270.0 / 29.0
		bank.append(Vector2(x, _fork_upper_y(x)))
	bank.append(Vector2(4030.0, _fork_upper_y(4030.0) + 46.0))
	bank.append(Vector2(2760.0, BASE_Y + 39.0))
	draw_colored_polygon(bank, Color("#8a8069"))
	for i in range(29):
		var x: float = 2760.0 + float(i) * 1270.0 / 29.0
		var nx: float = 2760.0 + float(i + 1) * 1270.0 / 29.0
		draw_line(Vector2(x, _fork_upper_y(x)), Vector2(nx, _fork_upper_y(nx)), Color("#d2bf95"), 6.0)
	# Two readable carved stone direction markers at the decision point.
	_draw_sign(2330.0, BASE_Y, "DUSHETI", false)
	_draw_sign(3150.0, _fork_upper_y(3150.0), "ANANURI", true)
	_draw_sign(4790.0, BASE_Y, "OLD TOWER", true)

func _draw_sign(x: float, y: float, _word: String, right: bool) -> void:
	draw_rect(Rect2(x - 5.0, y - 110.0, 10.0, 110.0), Color("#5a4939"))
	var board := PackedVector2Array()
	if right:
		board = PackedVector2Array([
			Vector2(x - 93.0, y - 119.0), Vector2(x + 65.0, y - 119.0),
			Vector2(x + 102.0, y - 99.0), Vector2(x + 65.0, y - 80.0),
			Vector2(x - 93.0, y - 80.0)
		])
	else:
		board = PackedVector2Array([
			Vector2(x + 93.0, y - 119.0), Vector2(x - 65.0, y - 119.0),
			Vector2(x - 102.0, y - 99.0), Vector2(x - 65.0, y - 80.0),
			Vector2(x + 93.0, y - 80.0)
		])
	draw_colored_polygon(board, Color("#8b7659"))

func _draw_landmarks() -> void:
	if area_index == 0:
		_draw_bridge(2880.0, BASE_Y)
		_draw_watch_fire(1060.0, _height_at(1060.0))
	elif area_index == 1:
		_draw_watch_fire(1000.0, BASE_Y)
	elif area_index == 2:
		for i in range(5):
			var x: float = 850.0 + float(i) * 1100.0
			_draw_terrace_wall(x, _height_at(x))
	elif area_index == 3:
		_draw_watch_fire(2430.0, _height_at(2430.0))
		_draw_highland_hut(4650.0, _height_at(4650.0))
	elif area_index == 4:
		_draw_bridge(3600.0, _height_at(3600.0))
	elif area_index == 5:
		_draw_bridge(3020.0, _height_at(3020.0))
	elif area_index == 6:
		_draw_ruined_tower(3940.0, _height_at(3940.0))
	elif area_index == 7:
		_draw_ananuri_tower(3820.0, _height_at(3820.0))
	elif area_index == 8:
		_draw_highland_hut(3710.0, _height_at(3710.0))

func _draw_bridge(x: float, y: float) -> void:
	# Historical masonry / wooden parapet, no modern dam or asphalt.
	draw_rect(Rect2(x - 250.0, y - 22.0, 500.0, 23.0), Color("#aca082"))
	for i in range(6):
		var bx: float = x - 225.0 + float(i) * 90.0
		draw_rect(Rect2(bx, y - 48.0, 13.0, 49.0), Color("#776c59"))
	draw_arc(Vector2(x, y + 90.0), 170.0, PI, TAU, 28, Color("#6f746b"), 22.0)

func _draw_watch_fire(x: float, y: float) -> void:
	draw_rect(Rect2(x - 28.0, y - 8.0, 56.0, 8.0), Color("#514137"))
	draw_line(Vector2(x - 16.0, y - 8.0), Vector2(x + 17.0, y - 8.0), Color("#4c342b"), 7.0)
	var flicker: float = sin(_clock * 6.0) * 6.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 11.0, y - 8.0), Vector2(x, y - 51.0 - flicker),
		Vector2(x + 14.0, y - 8.0)
	]), Color("#f1ad62"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 4.0, y - 7.0), Vector2(x, y - 29.0 - flicker * 0.5),
		Vector2(x + 6.0, y - 7.0)
	]), Color("#ffe3a1"))

func _draw_highland_hut(x: float, y: float) -> void:
	draw_rect(Rect2(x - 122.0, y - 115.0, 244.0, 115.0), Color("#817968"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 141.0, y - 116.0), Vector2(x, y - 189.0),
		Vector2(x + 143.0, y - 116.0)
	]), Color("#57574d"))
	draw_rect(Rect2(x - 25.0, y - 66.0, 50.0, 66.0), Color("#3d3831"))
	for i in range(8):
		var yy: float = y - 102.0 + float(i) * 13.0
		draw_line(Vector2(x - 115.0, yy), Vector2(x + 115.0, yy), Color("#5b554a", 0.58), 1.0)

func _draw_terrace_wall(x: float, y: float) -> void:
	draw_rect(Rect2(x - 137.0, y - 42.0, 274.0, 42.0), Color("#88826f"))
	for i in range(3):
		var yy: float = y - 30.0 + float(i) * 13.0
		draw_line(Vector2(x - 130.0, yy), Vector2(x + 130.0, yy), Color("#57554b", 0.6), 1.1)

func _draw_ruined_tower(x: float, y: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 100.0, y), Vector2(x - 94.0, y - 300.0),
		Vector2(x - 41.0, y - 319.0), Vector2(x + 30.0, y - 295.0),
		Vector2(x + 100.0, y - 274.0), Vector2(x + 106.0, y)
	]), Color("#75786b"))
	for row in range(6):
		var yy: float = y - 260.0 + float(row) * 41.0
		draw_line(Vector2(x - 92.0, yy), Vector2(x + 101.0, yy), Color("#54574d", 0.5), 1.3)
	draw_rect(Rect2(x - 19.0, y - 186.0, 36.0, 67.0), Color("#414941"))

func _draw_ananuri_tower(x: float, y: float) -> void:
	# Suggests an early road watchtower; the larger later Ananuri complex is not assumed.
	draw_rect(Rect2(x - 125.0, y - 310.0, 250.0, 310.0), Color("#b7a58c"))
	for i in range(8):
		var yy: float = y - 295.0 + float(i) * 34.0
		draw_line(Vector2(x - 120.0, yy), Vector2(x + 120.0, yy), Color("#786a59", 0.57), 1.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 141.0, y - 305.0), Vector2(x, y - 393.0),
		Vector2(x + 141.0, y - 305.0)
	]), Color("#6c6252"))
	draw_rect(Rect2(x - 17.0, y - 237.0, 34.0, 73.0), Color("#434139"))
	draw_rect(Rect2(x - 34.0, y - 72.0, 68.0, 72.0), Color("#423b34"))
