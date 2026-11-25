extends Node2D
## Jvari region. Five scene instances share this deterministic, gameplay-ready builder.
## Terrain colliders, traps, shrines and enemy instances are real physics objects.

const GROUND_Y: float = 650.0
const EnemyScene = preload("res://scenes/enemies/jvari_enemy.tscn")
const BoarScene = preload("res://scenes/enemies/wild_boar.tscn")
const HAZARD_SCENE_PATHS := {
	"spikes": "res://scenes/traps/jvari_spikes.tscn",
	"rock": "res://scenes/traps/falling_stone.tscn",
	"gust": "res://scenes/traps/wind_gust.tscn",
	"crumble": "res://scenes/traps/crumbling_ledge.tscn",
}
const REST_SCENE_PATH := "res://scenes/objects/rest_shrine.tscn"
const INSCRIPTION_SCENE_PATH := "res://scenes/objects/inscription.tscn"

@export_range(0, 4, 1) var area_index: int = 0
@export var area_width: float = 6200.0
@export var area_name: String = "Jvari - Confluence Trail"

var _pits: Array[Vector2] = []
var _ground_sections: Array[Vector2] = []
var _ascent_steps: Array[Vector3] = []
var _pilgrim_steps: Array[Vector3] = []
var _river_stones: Array[Vector2] = []
var _platforms: Array[Vector2] = []
var _pillars: Array[Vector2] = []
var _shrine_sites: Array[float] = []
var _time: float = 0.0
var _player: CharacterBody2D
var _finished: bool = false

func _ready() -> void:
	_player = get_node_or_null("Player") as CharacterBody2D
	_build_terrain()
	_build_challenges()
	_build_rest_sites()
	_build_story_moments()
	_build_title_banner()
	var world: Node = get_node_or_null("/root/WorldState")
	if world != null and world.has_method("enter_location"):
		world.call("enter_location", "jvari")
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if _player != null and is_instance_valid(_player) and _player.global_position.y > (_ground_height_at(_player.global_position.x) + 350.0 if area_index in [1, 3] else 940.0):
		var health: Node = _player.get_node_or_null("HealthComponent")
		if health != null and not bool(health.get("is_dead")):
			health.call("take_damage", 9999)

# Hand-authored set pieces make each zone identifiable rather than random repeats.
# Each gap is comfortably below the game's double-jump + dash reach.
const PIT_LAYOUTS: Array = [
	[[1840, 3720], [5130, 5340]],
	[[1210, 1420], [2580, 2800], [4540, 4790], [5930, 6130]],
	[[1100, 1330], [2440, 2680], [3770, 4010], [5500, 5760], [6600, 6810]],
	[[980, 1210], [2250, 2510], [3540, 3790], [4860, 5110], [6350, 6600], [7280, 7490]],
	[[1520, 1750], [2980, 3220], [4390, 4660], [5780, 6030], [7160, 7390]]
]
const PLATFORM_LAYOUTS: Array = [
	[[680, 550], [900, 500], [1180, 540], [1570, 535], [4080, 520], [4710, 520], [5190, 530], [5420, 500]],
	[[570, 555], [840, 500], [1080, 445], [1380, 535], [1650, 470], [1910, 414], [2290, 495], [2640, 525], [2910, 470], [3170, 420], [3580, 525], [3960, 465], [4380, 510], [4630, 470], [4900, 410], [5380, 510], [5780, 525], [6110, 470], [6480, 530]],
	[[650, 525], [920, 465], [1220, 530], [1510, 480], [1890, 540], [2330, 525], [2580, 475], [2920, 410], [3300, 520], [3700, 520], [3940, 470], [4300, 420], [4800, 525], [5320, 525], [5670, 475], [5980, 425], [6400, 520], [6710, 475], [7120, 535]],
	[[540, 550], [830, 490], [1120, 525], [1450, 470], [1830, 415], [2180, 530], [2480, 470], [2850, 420], [3260, 545], [3590, 500], [3880, 440], [4320, 520], [4790, 525], [5040, 460], [5400, 395], [5910, 540], [6280, 485], [6550, 435], [6890, 520], [7350, 500], [7650, 455]],
	[[630, 540], [930, 490], [1290, 530], [1650, 520], [1990, 465], [2420, 525], [2890, 510], [3170, 455], [3510, 405], [3910, 530], [4400, 520], [4640, 460], [4980, 410], [5440, 530], [5790, 500], [6030, 450], [6400, 410], [6950, 530], [7190, 480], [7480, 425], [7990, 535]]
]
const ENEMY_LAYOUTS: Array = [
	[[1050, "sentry"], [1620, "raider"], [4240, "raider"], [5650, "sentry"]],
	[[750, "sentry"], [1690, "raider"], [2140, "sentry"], [3210, "raider"], [4130, "raider"], [5120, "sentry"], [6330, "raider"]],
	[[780, "wraith"], [1740, "sentry"], [2990, "wraith"], [3490, "raider"], [4580, "wraith"], [6040, "wraith"], [7110, "raider"]],
	# JVARI_PASS_WARDENS_V1: Stone Ascent Wardens moved to the final pass arena.
	[[740, "raider"], [1730, "sentry"], [3050, "raider"], [4140, "sentry"], [5470, "raider"], [6920, "raider"], [7830, "sentry"]],
	[[1040, "sentry"], [2220, "raider"], [3560, "warden"], [5020, "raider"], [6260, "warden"], [7620, "warden"]]
]
# Hazard positions and types, composed as identifiable encounters.
const HAZARD_LAYOUTS: Array = [
	[[1260,"spikes"],[4060,"rock"],[4620,"spikes"],[5570,"crumble"]],
	[[690,"crumble"],[1640,"rock"],[2040,"spikes"],[3120,"crumble"],[3650,"rock"],[4270,"spikes"],[5020,"rock"],[5560,"crumble"],[6380,"spikes"]],
	[[720,"gust"],[1640,"rock"],[1920,"gust"],[2950,"spikes"],[3480,"gust"],[4440,"rock"],[4810,"gust"],[6070,"rock"],[6250,"gust"],[7080,"spikes"]],
	[[750,"spikes"],[1620,"crumble"],[2070,"rock"],[2850,"crumble"],[3240,"spikes"],[4210,"rock"],[4650,"gust"],[5380,"crumble"],[6080,"spikes"],[6770,"rock"],[7610,"crumble"]],
	[[1150,"spikes"],[2110,"rock"],[2520,"crumble"],[3400,"spikes"],[4020,"rock"],[4960,"gust"],[5520,"crumble"],[6300,"spikes"],[6860,"rock"],[7750,"crumble"]]
]

func camera_bounds() -> Rect2i:
	var top := floori(_ground_height_at(area_width) - 650.0)
	return Rect2i(0, top, roundi(area_width), 800 - top)


func _build_terrain() -> void:
	if area_index == 3:
		_build_stone_ascent()
		return
	if area_index == 1:
		_build_pilgrim_ascent()
		return
	for bounds: Array in PIT_LAYOUTS[area_index]:
		_pits.append(Vector2(float(bounds[0]),float(bounds[1])))
	var x: float = 0.0
	for gap: Vector2 in _pits:
		_add_ground_section(x, gap.x)
		x = gap.y
	_add_ground_section(x, area_width)
	_make_solid("LeftBoundary", Vector2(-16.0,230.0),Vector2(32,1100))
	_make_solid("RightBoundary", Vector2(area_width+16.0,230.0),Vector2(32,1100))
	if area_index == 0:
		_build_river_stepping_stones()
	for i: int in range(PLATFORM_LAYOUTS[area_index].size()):
		var layout: Array = PLATFORM_LAYOUTS[area_index][i]
		var px: float = float(layout[0])
		var py: float = float(layout[1])
		_platforms.append(Vector2(px,py))
		_make_solid("Step_%02d" % i,Vector2(px,py+9.0),Vector2(168,18),true)
	# Large stone obstructions reinforce the architecture and create combat cover.
	var obstacles: Array = [
		[2860, 70], [4570, 82],
		[1870, 80], [3370, 95], [5270, 80],
		[2090, 70], [3360, 85], [5950, 72],
		[1810, 75], [3100, 100], [5660, 104],
		[2460, 85], [4010, 115], [6470, 96]
	]
	var stride: int = [2,3,3,3,3][area_index]
	var base: int = [0,2,5,8,11][area_index]
	for i: int in range(stride):
		var item: Array = obstacles[base+i]
		var bx: float = float(item[0])
		var h: float = float(item[1])
		if _near_gap(bx,100.0):
			continue
		_pillars.append(Vector2(bx,h))
		_make_solid("RockObstruction_%d" % i, Vector2(bx,GROUND_Y-h*0.5),Vector2(58,h))

# Real vertical traversal: 31 consecutive stone terraces climb by 1,140 px.
# 250 px-wide terraces / 38 px-high risers are climbable without special abilities.
# Geometry, visual stonework, enemy footing, hazards and exits share one height function.
const ASCENT_START: float = 340.0
const ASCENT_RUN: float = 250.0
const ASCENT_RISE: float = 38.0
const ASCENT_LAST_STEP: int = 30

func _ascent_ground_at(x: float) -> float:
	var step_index: int = clampi(int(floor((x - ASCENT_START) / ASCENT_RUN)) + 1, 0, ASCENT_LAST_STEP)
	return GROUND_Y - float(step_index) * ASCENT_RISE

func _build_stone_ascent() -> void:
	_make_solid("LeftBoundary", Vector2(-16.0, -450.0), Vector2(32.0, 2500.0))
	_make_solid("RightBoundary", Vector2(area_width + 16.0, -450.0), Vector2(32.0, 2500.0))
	var x: float = 0.0
	for i in range(ASCENT_LAST_STEP + 1):
		var end_x: float = minf(area_width, ASCENT_START + float(i) * ASCENT_RUN)
		if end_x > x:
			var top: float = GROUND_Y - float(i) * ASCENT_RISE
			_ascent_steps.append(Vector3(x, end_x, top))
			# Thick individual step: actual upper surface is at y=top.
			_make_solid("AscentTerrace_%02d" % i, Vector2((x+end_x)*0.5, top+120.0), Vector2(end_x-x, 240.0))
			x = end_x
	if x < area_width:
		var top: float = _ascent_ground_at(area_width - 1.0)
		_ascent_steps.append(Vector3(x, area_width, top))
		_make_solid("SummitTerrace", Vector2((x+area_width)*0.5, top+120.0), Vector2(area_width-x,240.0))
	# Optional side ledges are built above, not in place of, the main stairway.
	for i in range(13):
		var px: float = 760.0 + float(i)*565.0
		var py: float = _ascent_ground_at(px) - 132.0 - float(i%3)*35.0
		_platforms.append(Vector2(px,py))
		_make_solid("HighLedge_%02d" % i, Vector2(px,py+9.0), Vector2(170.0,18.0), true)
	# Deliberate obstacles add jump-and-fight beats without blocking the ascent.
	for i in range(7):
		var bx: float = 1375.0 + float(i) * 945.0
		var h: float = 55.0 + float(i % 3) * 10.0
		_pillars.append(Vector2(bx,h))
		_make_solid("AscentRock_%02d" % i, Vector2(bx,_ascent_ground_at(bx)-h*0.5),Vector2(52.0,h))

# Confluence river: a 1,880 px wide actual collision gap with nine small rock islands.
# Each top surface is walkable; the water below is lethal through the fall check.
const RIVER_LEFT: float = 1840.0
const RIVER_RIGHT: float = 3720.0
const RIVER_STONE_COUNT: int = 9

func _build_river_stepping_stones() -> void:
	for i in range(RIVER_STONE_COUNT):
		var xx: float = 1915.0 + float(i) * 205.0
		var top_y: float = 636.0 - float(i % 3) * 16.0
		_river_stones.append(Vector2(xx, top_y))
		_make_solid("RiverStone_%02d" % i, Vector2(xx, top_y + 18.0), Vector2(140.0, 36.0))

# Pilgrims physically climb 25 low stone risers, gaining 850px of elevation.
# The climb starts and ends on uninterrupted walking surfaces.
const PILGRIM_START: float = 340.0
const PILGRIM_RUN: float = 245.0
const PILGRIM_RISE: float = 34.0
const PILGRIM_LAST_STEP: int = 25

func _pilgrim_ground_at(x: float) -> float:
	var step_index: int = clampi(int(floor((x - PILGRIM_START) / PILGRIM_RUN)) + 1, 0, PILGRIM_LAST_STEP)
	return GROUND_Y - float(step_index) * PILGRIM_RISE

func _ground_height_at(x: float) -> float:
	if area_index == 1:
		return _pilgrim_ground_at(x)
	if area_index == 3:
		return _ascent_ground_at(x)
	return GROUND_Y

func _build_pilgrim_ascent() -> void:
	_make_solid("LeftBoundary", Vector2(-16.0, -250.0), Vector2(32.0, 2200.0))
	_make_solid("RightBoundary", Vector2(area_width + 16.0, -250.0), Vector2(32.0, 2200.0))
	var left_x: float = 0.0
	for i in range(PILGRIM_LAST_STEP + 1):
		var right_x: float = minf(area_width, PILGRIM_START + float(i) * PILGRIM_RUN)
		if right_x > left_x:
			var y: float = GROUND_Y - float(i) * PILGRIM_RISE
			_pilgrim_steps.append(Vector3(left_x, right_x, y))
			_make_solid("PilgrimTerrace_%02d" % i, Vector2((left_x + right_x) * 0.5, y + 130.0), Vector2(right_x - left_x, 260.0))
			left_x = right_x
	if left_x < area_width:
		var summit_y: float = _pilgrim_ground_at(area_width - 1.0)
		_pilgrim_steps.append(Vector3(left_x, area_width, summit_y))
		_make_solid("PilgrimSummit", Vector2((left_x + area_width) * 0.5, summit_y + 130.0), Vector2(area_width - left_x, 260.0))
	for i in range(11):
		var xx: float = 650.0 + float(i) * 570.0
		var yy: float = _pilgrim_ground_at(xx) - 135.0 - float(i % 3) * 24.0
		_platforms.append(Vector2(xx, yy))
		_make_solid("PilgrimLedge_%02d" % i, Vector2(xx, yy + 9.0), Vector2(160.0, 18.0), true)
	for i in range(6):
		var xx: float = 1200.0 + float(i) * 940.0
		var height: float = 56.0 + float(i % 3) * 8.0
		_pillars.append(Vector2(xx, height))
		_make_solid("PilgrimBoulder_%02d" % i, Vector2(xx, _pilgrim_ground_at(xx) - height * 0.5), Vector2(52.0, height))

func _add_ground_section(start_x: float, end_x: float) -> void:
	if end_x - start_x <= 5.0:
		return
	_ground_sections.append(Vector2(start_x, end_x))
	_make_solid("Ground_%d" % int(start_x), Vector2((start_x + end_x) * 0.5, GROUND_Y + 95.0), Vector2(end_x - start_x, 190))

func _make_solid(solid_name: String, center: Vector2, size: Vector2, one_way: bool = false) -> void:
	var body := StaticBody2D.new()
	body.name = solid_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.one_way_collision = one_way
	body.add_child(shape)
	add_child(body)

func _near_gap(x: float, margin: float) -> bool:
	for pit: Vector2 in _pits:
		if x >= pit.x - margin and x <= pit.y + margin:
			return true
	return false

func _near_rest(x: float, margin: float) -> bool:
	# The only rest sanctuary is near the beginning of Confluence Trail.
	return area_index == 0 and absf(x - 420.0) < margin

func _load_optional_scene(path: String) -> PackedScene:
	# Some checkouts have these optional set pieces outside the tracked project.
	return load(path) as PackedScene if ResourceLoader.exists(path, "PackedScene") else null


func _build_challenges() -> void:
	var hazard_scenes: Dictionary[String, PackedScene] = {}
	for kind: String in HAZARD_SCENE_PATHS:
		hazard_scenes[kind] = _load_optional_scene(HAZARD_SCENE_PATHS[kind])
	for i: int in range(HAZARD_LAYOUTS[area_index].size()):
		var layout: Array = HAZARD_LAYOUTS[area_index][i]
		var x: float = float(layout[0])
		var kind: String = str(layout[1])
		if _near_gap(x,65.0) or _near_rest(x,200.0):
			continue
		var scene: PackedScene = hazard_scenes[kind]
		if scene == null:
			continue
		var obstacle := scene.instantiate() as Node2D
		match kind:
			"spikes":
				obstacle.position = Vector2(x,_ground_height_at(x)-10.0)
				obstacle.set("damage",10+area_index*2)
			"rock":
				obstacle.position = Vector2(x,_ground_height_at(x)-390.0)
				if area_index in [1, 3]:
					obstacle.set("ground_target_y", _ground_height_at(x)-24.0)
				obstacle.set("damage",12+area_index*2)
			"gust":
				obstacle.position = Vector2(x,_ground_height_at(x)-112.0)
				obstacle.set("force",470.0+float(area_index)*85.0)
				obstacle.set("direction", -1.0 if i%2==0 else 1.0)
			"crumble":
				obstacle.position = Vector2(x,_ground_height_at(x)-134.0)
				obstacle.set("recovery_seconds",3.0+float(area_index)*0.35)
		add_child(obstacle)
	for i: int in range(ENEMY_LAYOUTS[area_index].size()):
		var spec: Array = ENEMY_LAYOUTS[area_index][i]
		var x: float = float(spec[0])
		var kind: String = str(spec[1])
		if _near_gap(x,92.0) or _near_rest(x,180.0):
			continue
		# JVARI_BOAR_ONLY_MONASTERY_V1
		if area_index == 4:
			# Dedicated, reusable boar scene: no sentries/raiders/wardens in Jvari Monastery.
			var boar: Node2D = BoarScene.instantiate() as Node2D
			boar.position = Vector2(x, _ground_height_at(x) - 30.0)
			add_child(boar)
		else:
			var enemy: Node2D = EnemyScene.instantiate() as Node2D
			enemy.set("archetype",kind)
			enemy.set("difficulty",area_index)
			enemy.position = Vector2(x, _ground_height_at(x) - (175.0 if kind == "wraith" else 44.0))
			add_child(enemy)

func _build_rest_sites() -> void:
	if area_index != 0:
		return
	var rest_scene := _load_optional_scene(REST_SCENE_PATH)
	if rest_scene == null:
		return
	var x: float = 420.0
	_shrine_sites.append(x)
	var shrine := rest_scene.instantiate() as Node2D
	shrine.position = Vector2(x,GROUND_Y)
	shrine.set("spawn_id","jvari_first_rest")
	add_child(shrine)
	var spawn := Marker2D.new()
	spawn.name = "JvariFirstRestSpawn"
	spawn.position = Vector2(x,602.0)
	spawn.set_script(preload("res://scripts/levels/mtskheta/spawn_point.gd"))
	spawn.set("spawn_id","jvari_first_rest")
	add_child(spawn)

func _build_story_moments() -> void:
	var inscription_scene := _load_optional_scene(INSCRIPTION_SCENE_PATH)
	if inscription_scene == null:
		return
	var scriptural := inscription_scene.instantiate() as Node2D
	scriptural.position = Vector2(area_width - 610.0, _ground_height_at(area_width - 610.0))
	match area_index:
		0:
			scriptural.set("message", "Below, Aragvi and Mtkvari meet. Above, the path asks what you are willing to lose.")
		1:
			scriptural.set("message", "A pilgrim left this scratched prayer: let no soul become a stranger to their own blood.")
		2:
			scriptural.set("message", "Wind carries no judgment. It carries names. Samdzivari's is among them.")
		3:
			scriptural.set("message", "The monks watched strangers pass to the highlands. One woman walked alone.")
		_:
			scriptural.set("message", "Xizane, she is not buried in these stones. Walk toward the mountain passes.")
	add_child(scriptural)

func _build_title_banner() -> void:
	# A restrained arrival title, always on-screen during scene transitions.
	var subtitles: Array[String] = [
		"THE MEETING OF THE RIVERS",
		"THE ROAD RISES TO THE HOLY CROSS",
		"THE MOUNTAIN SPEAKS IN WIND",
		"THE LAST STONE ASCENT",
		"THE CHURCH OF THE HOLY CROSS"
	]
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -350.0
	panel.offset_right = 350.0
	panel.offset_top = 65.0
	panel.offset_bottom = 150.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_constant_override("separation", 4)
	layer.add_child(panel)
	var name_label := Label.new()
	name_label.text = area_name.to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color("#f4e6bf"))
	name_label.add_theme_color_override("font_outline_color", Color("#28332f"))
	name_label.add_theme_constant_override("outline_size", 6)
	panel.add_child(name_label)
	var subtitle := Label.new()
	subtitle.text = subtitles[area_index]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#e3d5b5"))
	panel.add_child(subtitle)
	var tween := create_tween()
	tween.tween_interval(3.4)
	tween.tween_property(panel, "modulate:a", 0.0, 0.9)
	tween.tween_callback(layer.queue_free)

func _draw() -> void:
	_draw_sky()
	_draw_mountains()
	if area_index == 4:
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
	elif area_index >= 2 and area_index != 3:
		_draw_monastery(area_width - 1600.0, 0.38)

func _draw_sky() -> void:
	var top := Color("#ede0c4")
	var bottom := Color("#d3bd9b")
	if area_index >= 2:
		top = Color("#e4d8bb")
		bottom = Color("#b7baa3")
	for i in range(25):
		var t: float = float(i) / 24.0
		draw_rect(Rect2(0.0, -1900.0 + float(i) * 114.0, area_width, 115.0), top.lerp(bottom, t))
	draw_circle(Vector2(area_width * 0.73, -60), 105.0, Color("#ffedbc", 0.22))

func _draw_mountains() -> void:
	if area_index == 1:
		_draw_pilgrim_ridge(-385.0, 28.0, Color("#a4b18f"), 0.5)
		_draw_pilgrim_ridge(-245.0, 43.0, Color("#889c78"), 1.5)
		_draw_pilgrim_ridge(-140.0, 32.0, Color("#657b60"), 3.7)
		return
	if area_index == 3:
		_draw_ascent_ridge(-450.0, 29.0, Color("#a4b18f"), 1.0)
		_draw_ascent_ridge(-290.0, 45.0, Color("#889c78"), 2.2)
		_draw_ascent_ridge(-155.0, 37.0, Color("#657b60"), 4.4)
		return
	_draw_ridge(315.0 + float(area_index) * 8.0, 23.0, 740.0, Color("#a4b18f"), 0.0)
	_draw_ridge(440.0, 38.0, 570.0, Color("#8b9d7a"), 1.1)
	_draw_ridge(549.0, 46.0, 410.0, Color("#617b62"), 2.6)

func _draw_pilgrim_ridge(vertical_offset: float, waviness: float, tint: Color, phase: float) -> void:
	var pts := PackedVector2Array()
	for i in range(int(area_width / 42.0) + 2):
		var xx: float = minf(float(i) * 42.0, area_width)
		var yy: float = _pilgrim_ground_at(xx) + vertical_offset + sin(xx / 410.0 + phase) * waviness
		pts.append(Vector2(xx, yy))
	pts.append(Vector2(area_width, 1100.0))
	pts.append(Vector2(0.0, 1100.0))
	draw_colored_polygon(pts, tint)

func _draw_ascent_ridge(vertical_offset: float, waviness: float, tint: Color, phase: float) -> void:
	var pts := PackedVector2Array()
	for i in range(int(area_width / 42.0)+2):
		var xx: float = minf(float(i)*42.0,area_width)
		var yy: float = _ascent_ground_at(xx) + vertical_offset + sin(xx/350.0+phase)*waviness
		pts.append(Vector2(xx,yy))
	pts.append(Vector2(area_width,1050.0))
	pts.append(Vector2(0.0,1050.0))
	draw_colored_polygon(pts,tint)

func _draw_ridge(base: float, height: float, wavelength: float, tint: Color, phase: float) -> void:
	var points := PackedVector2Array()
	for i in range(int(area_width / 30.0) + 2):
		var x: float = minf(float(i) * 30.0, area_width)
		var y: float = base + sin(x / wavelength + phase) * height + sin(x / (wavelength * 0.43) + phase * 2.0) * height * 0.35
		points.append(Vector2(x, y))
	points.append(Vector2(area_width, GROUND_Y + 45))
	points.append(Vector2(0, GROUND_Y + 45))
	draw_colored_polygon(points, tint)

func _draw_confluence() -> void:
	# The two rivers below the ascent meet in the distant valley.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 579), Vector2(510, 597), Vector2(950, 610), Vector2(1680, 625), Vector2(1680, 650), Vector2(0, 650)]), Color("#7f9d9b", 0.7))
	draw_colored_polygon(PackedVector2Array([Vector2(480, 610), Vector2(760, 570), Vector2(1020, 590), Vector2(1300, 635), Vector2(1300, 650), Vector2(480, 650)]), Color("#aac1ae", 0.45))

func _draw_road() -> void:
	if area_index == 1:
		_draw_pilgrim_road()
		return
	if area_index == 3:
		_draw_ascent_road()
		return
	for segment: Vector2 in _ground_sections:
		var start: float = segment.x
		var width: float = segment.y - segment.x
		draw_rect(Rect2(start, GROUND_Y, width, 230), Color("#75674f"))
		draw_rect(Rect2(start, GROUND_Y, width, 7), Color("#82916b"))
		draw_line(Vector2(start, GROUND_Y + 9), Vector2(segment.y, GROUND_Y + 9), Color("#baaa85"), 2.0)
		for row in range(4):
			var y: float = GROUND_Y + 39.0 + float(row) * 45.0
			draw_line(Vector2(start, y), Vector2(segment.y, y), Color("#5e5947", 0.65), 1.2)
	for step: Vector2 in _platforms:
		draw_rect(Rect2(step.x - 84.0, step.y, 168.0, 17.0), Color("#8b846b"))
		draw_rect(Rect2(step.x - 84.0, step.y, 168.0, 5.0), Color("#c3ad86"))
		for i in range(3):
			draw_line(Vector2(step.x - 57 + i * 52, step.y + 5), Vector2(step.x - 57 + i * 52, step.y + 16), Color("#655e4c"), 1)
	for pillar: Vector2 in _pillars:
		draw_rect(Rect2(pillar.x - 29, GROUND_Y - pillar.y, 58, pillar.y), Color("#706f5a"))
		draw_rect(Rect2(pillar.x - 31, GROUND_Y - pillar.y - 7, 62, 9), Color("#a49b7b"))
	for pit: Vector2 in _pits:
		draw_rect(Rect2(pit.x, GROUND_Y + 9, pit.y - pit.x, 160), Color("#272d2a"))
		draw_line(Vector2(pit.x - 9, GROUND_Y), Vector2(pit.x + 5, GROUND_Y + 47), Color("#ba9a70"), 3.0)
		draw_line(Vector2(pit.y + 9, GROUND_Y), Vector2(pit.y - 5, GROUND_Y + 47), Color("#ba9a70"), 3.0)

func _draw_pilgrim_road() -> void:
	for terrace: Vector3 in _pilgrim_steps:
		var left: float = terrace.x
		var right: float = terrace.y
		var top: float = terrace.z
		draw_rect(Rect2(left, top, right - left, 850.0), Color("#756b54"))
		draw_rect(Rect2(left, top, right - left, 10.0), Color("#bea883"))
		for j in range(5):
			var yy: float = top + 36.0 + float(j) * 40.0
			draw_line(Vector2(left, yy), Vector2(right, yy), Color("#5a5549", 0.76), 1.3)
			var joint: float = left + 45.0 + float(j % 2) * 47.0
			while joint < right:
				draw_line(Vector2(joint, yy - 37.0), Vector2(joint, yy), Color("#564e42", 0.62), 1.0)
				joint += 115.0
	for platform: Vector2 in _platforms:
		draw_rect(Rect2(platform.x - 80.0, platform.y, 160.0, 18.0), Color("#807863"))
		draw_rect(Rect2(platform.x - 80.0, platform.y, 160.0, 5.0), Color("#c3b18b"))
	for pillar: Vector2 in _pillars:
		var top: float = _pilgrim_ground_at(pillar.x)
		draw_rect(Rect2(pillar.x - 26.0, top - pillar.y, 52.0, pillar.y), Color("#77705c"))
		draw_rect(Rect2(pillar.x - 27.0, top - pillar.y - 7.0, 54.0, 9.0), Color("#b9a685"))

func _draw_wide_river() -> void:
	# The actual traversable river gap is eight times the old ~230px cracks.
	var span: float = RIVER_RIGHT - RIVER_LEFT
	draw_rect(Rect2(RIVER_LEFT, GROUND_Y + 15.0, span, 390.0), Color("#496f74"))
	for k in range(11):
		var yy: float = GROUND_Y + 30.0 + float(k) * 21.0
		draw_line(Vector2(RIVER_LEFT + 12.0, yy), Vector2(RIVER_RIGHT - 14.0, yy + float(k % 3) * 5.0), Color("#8db7ad", 0.32), 3.0)
	for i in range(24):
		var xx: float = RIVER_LEFT + 30.0 + float(i) * 75.0
		draw_line(Vector2(xx, GROUND_Y + 53.0 + float(i % 4) * 29.0), Vector2(xx + 41.0, GROUND_Y + 48.0 + float(i % 4) * 29.0), Color("#d9d9ba", 0.34), 2.0)
	# Small islands are visible above the water and backed by real collision shapes.
	for i in range(_river_stones.size()):
		var stone: Vector2 = _river_stones[i]
		var xx: float = stone.x
		var yy: float = stone.y
		draw_colored_polygon(PackedVector2Array([Vector2(xx - 77.0, yy + 15.0), Vector2(xx - 67.0, yy - 3.0), Vector2(xx + 60.0, yy - 3.0), Vector2(xx + 78.0, yy + 18.0), Vector2(xx + 52.0, yy + 55.0), Vector2(xx - 54.0, yy + 55.0)]), Color("#696f65"))
		draw_line(Vector2(xx - 65.0, yy), Vector2(xx + 60.0, yy), Color("#d0c3a1"), 5.0)
		draw_line(Vector2(xx - 35.0, yy + 22.0), Vector2(xx + 22.0, yy + 26.0), Color("#a5a78b", 0.65), 2.0)

func _draw_ascent_road() -> void:
	for stair: Vector3 in _ascent_steps:
		var left: float = stair.x
		var right: float = stair.y
		var top: float = stair.z
		var width: float = right - left
		draw_rect(Rect2(left,top,width,820.0),Color("#696451"))
		draw_rect(Rect2(left,top,width,10.0),Color("#b8a57b"))
		draw_rect(Rect2(left,top+12.0,width,11.0),Color("#84916b"))
		for row in range(5):
			var yy: float = top+44.0+float(row)*43.0
			draw_line(Vector2(left,yy),Vector2(right,yy),Color("#504d41",0.65),1.5)
			var joint_x: float = left + (float(row%2)*46.0) + 90.0
			while joint_x < right:
				draw_line(Vector2(joint_x,yy-40.0),Vector2(joint_x,yy),Color("#4e4b3d",0.5),1.1)
				joint_x += 115.0
		if left >= ASCENT_START:
			draw_rect(Rect2(left-7,top,14,ASCENT_RISE),Color("#bca783"))
	for platform: Vector2 in _platforms:
		draw_rect(Rect2(platform.x-85.0,platform.y,170.0,18.0),Color("#797460"))
		draw_rect(Rect2(platform.x-85.0,platform.y,170.0,5.0),Color("#c6b48d"))
	for pillar: Vector2 in _pillars:
		var by: float = _ascent_ground_at(pillar.x)
		draw_rect(Rect2(pillar.x-26.0,by-pillar.y,52.0,pillar.y),Color("#666353"))
		draw_rect(Rect2(pillar.x-28.0,by-pillar.y-7.0,56.0,9.0),Color("#b3a17c"))

func _draw_signature_landscape() -> void:
	match area_index:
		0:
			# Confluence: river gorge, riverbank cliffs and an old pilgrim bridge.
			_draw_river_ribbon(60.0, 1510.0, 560.0)
			_draw_river_ribbon(470.0, 1520.0, 605.0)
			_draw_bridge(1110.0, 615.0, 0.74)
			for i in range(6):
				_draw_olive(540.0 + float(i)*870.0, GROUND_Y, 1.0 + float(i%3)*0.16)
		1:
			# Pilgrim Steps: ochre terraced hillside, roadside arcades and votive niches.
			for i in range(16):
				var x: float = float(i)*460.0
				var y: float = _pilgrim_ground_at(x) - 165.0 - float(i%4)*22.0
				draw_colored_polygon(PackedVector2Array([Vector2(x,y+70),Vector2(x+280,y+20),Vector2(x+420,y+50),Vector2(x+420,_pilgrim_ground_at(x+420)),Vector2(x,_pilgrim_ground_at(x))]),Color("#a8a080",0.62))
			for i in range(5):
				_draw_pilgrim_niche(620.0 + float(i)*1250.0, _pilgrim_ground_at(620.0 + float(i)*1250.0), 1.0)
		2:
			# Windcut: a sharply incised ravine and fog bands between dark cliffs.
			for i in range(9):
				var x: float = 400.0 + float(i)*895.0
				draw_colored_polygon(PackedVector2Array([Vector2(x-340,GROUND_Y),Vector2(x-185,380),Vector2(x-40,460),Vector2(x+75,325),Vector2(x+190,GROUND_Y)]),Color("#56685e",0.48))
			for i in range(14):
				var x: float = 100.0 + float(i)*570.0
				draw_line(Vector2(x,390.0+float(i%3)*90),Vector2(x+220.0,375.0+float(i%3)*90),Color("#d6d8c4",0.35),10.0)
		3:
			# Vertical framing reinforces the gain in altitude as the player climbs.
			for i in range(12):
				var x: float = 540.0 + float(i)*670.0
				var ground: float = _ascent_ground_at(x)
				draw_colored_polygon(PackedVector2Array([Vector2(x-290,ground+150),Vector2(x-180,ground-220),Vector2(x-75,ground-180),Vector2(x+45,ground-330),Vector2(x+170,ground+150)]),Color("#596b5b",0.56))
				if i%2 == 0:
					_draw_cross(x,ground,0.52)
			# Summit comes into view as the road rises.
			_draw_monastery(7730.0,0.53,_ascent_ground_at(7730.0)-240.0)
		4:
			# Jvari stands on a rocky high plateau above the two rivers.
			for i in range(5):
				var xx: float = 730.0 + float(i) * 1030.0
				_draw_pilgrim_niche(xx, GROUND_Y, 0.78)
			draw_colored_polygon(PackedVector2Array([Vector2(5750.0, 650.0),Vector2(6030.0, 430.0),Vector2(6730.0, 360.0),Vector2(7840.0, 490.0),Vector2(8360.0,650.0)]),Color("#5b6e5c",0.52))
			draw_rect(Rect2(6380.0, 620.0, 1790.0, 30.0), Color("#9e8e70"))
			for j in range(12):
				var xx: float = 6420.0 + float(j) * 132.0
				draw_line(Vector2(xx, 630.0),Vector2(xx, 645.0),Color("#635c4c",0.73),2.0)

func _draw_river_ribbon(x: float, width: float, y: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x,y+26),Vector2(x+width*0.23,y-9),Vector2(x+width*0.58,y+8),Vector2(x+width,y+49),Vector2(x+width,y+79),Vector2(x,y+66)]),Color("#8caeaa",0.85))
	draw_line(Vector2(x+65.0,y+37.0),Vector2(x+width-130.0,y+55.0),Color("#d8d7bd",0.53),3.0)

func _draw_bridge(x: float, y: float, scale_factor: float) -> void:
	var f: float = scale_factor
	var stone: Color = Color("#827b63")
	draw_rect(Rect2(x-185.0*f,y-22.0*f,370.0*f,19.0*f),Color("#b0a080"))
	for k in range(4):
		var bx: float = x + (-165.0+float(k)*110.0)*f
		draw_rect(Rect2(bx,y-55.0*f,16.0*f,55.0*f),stone)
	draw_arc(Vector2(x,y+44.0*f),100.0*f,PI,TAU,24,stone,10.0)

func _draw_olive(x: float, y: float, scale_factor: float) -> void:
	var f: float = scale_factor
	draw_line(Vector2(x,y),Vector2(x-13.0*f,y-124.0*f),Color("#535747"),9.0*f)
	draw_line(Vector2(x-10.0*f,y-84.0*f),Vector2(x+32.0*f,y-110.0*f),Color("#535747"),5.0*f)
	draw_circle(Vector2(x-36.0*f,y-151.0*f),50.0*f,Color("#637b5d",0.83))
	draw_circle(Vector2(x+20.0*f,y-145.0*f),56.0*f,Color("#738c68",0.80))

func _draw_pilgrim_niche(x: float, y: float, scale_factor: float) -> void:
	var f: float = scale_factor
	draw_rect(Rect2(x-40.0*f,y-125.0*f,80.0*f,125.0*f),Color("#776e5d"))
	draw_rect(Rect2(x-48.0*f,y-129.0*f,96.0*f,15.0*f),Color("#c0ad89"))
	draw_rect(Rect2(x-18.0*f,y-94.0*f,36.0*f,70.0*f),Color("#3f453d"))
	draw_rect(Rect2(x-3.0*f,y-81.0*f,6.0*f,38.0*f),Color("#b4a385"))
	draw_rect(Rect2(x-14.0*f,y-68.0*f,28.0*f,6.0*f),Color("#b4a385"))

func _draw_trees() -> void:
	if area_index == 1:
		for i in range(17):
			var x: float = 155.0 + float(i) * 390.0
			_draw_olive(x, _pilgrim_ground_at(x), 0.53 + float(i % 3) * 0.12)
		return
	if area_index == 3:
		for i in range(18):
			var x: float = 145.0 + float(i)*445.0
			var y: float = _ascent_ground_at(x)
			_draw_olive(x,y,0.58 + float(i%3)*0.10)
		return
	for i in range(int(area_width / 285.0)):
		var x: float = 125.0 + float(i) * 285.0
		if _near_gap(x, 90.0) or _near_rest(x, 115.0):
			continue
		var height: float = 39.0 + float((i * 7) % 4) * 11.0
		draw_line(Vector2(x, GROUND_Y), Vector2(x - 3, GROUND_Y - height), Color("#4e5545"), 4)
		draw_circle(Vector2(x - 5, GROUND_Y - height), height * 0.45, Color("#526e56", 0.8))
		draw_circle(Vector2(x + 9, GROUND_Y - height * 0.85), height * 0.35, Color("#79916b", 0.8))

func _draw_jvari_distant_view() -> void:
	# The actual monastery near x=7220 is invisible at the area entrance.
	# A small, muted skyline view introduces its distinct cross-domed form immediately.
	# This is scenery only; no new collision, checkpoints, or enemy changes.
	var ridge := PackedVector2Array([
		Vector2(340.0, 690.0), Vector2(510.0, 490.0),
		Vector2(810.0, 385.0), Vector2(1080.0, 380.0),
		Vector2(1330.0, 475.0), Vector2(1570.0, 690.0)
	])
	draw_colored_polygon(ridge, Color("#748a72", 0.73))
	_draw_monastery(950.0, 0.52, 380.0)

func _draw_monastery(x: float, scale_factor: float, location_y: float = 480.0) -> void:
	# Jvari's compact sixth-century tetraconch exterior: projecting apses,
	# low cross arms, an octagonal drum, shallow pyramidal roof, and single cross.
	# No tall western steeple or invented castle towers.
	var p := Vector2(x, location_y)
	var f: float = scale_factor
	var shadow := Color("#5c554b")
	var wall := Color("#a69678")
	var sunlit := Color("#c1ac85")
	var roof := Color("#806e58")
	# Rocky promontory under the monastery.
	draw_colored_polygon(PackedVector2Array([p + Vector2(-260, 20) * f, p + Vector2(-160, -35) * f, p + Vector2(105, -30) * f, p + Vector2(240, 20) * f]), Color("#62705a"))
	# Projecting side apses and short cross arms.
	draw_rect(Rect2(p + Vector2(-163, -87) * f, Vector2(92, 89) * f), shadow)
	draw_rect(Rect2(p + Vector2(71, -91) * f, Vector2(89, 93) * f), wall)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-169,-87)*f,p + Vector2(-118,-110)*f,p + Vector2(-65,-87)*f]),roof)
	draw_colored_polygon(PackedVector2Array([p + Vector2(65,-91)*f,p + Vector2(115,-117)*f,p + Vector2(166,-91)*f]),roof)
	# Broad central stone mass with projecting facade and shallow gable.
	draw_rect(Rect2(p + Vector2(-103,-119)*f,Vector2(206,121)*f),wall)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-115,-119)*f,p+Vector2(0,-156)*f,p+Vector2(115,-119)*f]),sunlit)
	# Four visible angled faces evoke the polygonal octagonal drum.
	draw_colored_polygon(PackedVector2Array([p+Vector2(-54,-175)*f,p+Vector2(-36,-198)*f,p+Vector2(36,-198)*f,p+Vector2(54,-175)*f,p+Vector2(54,-140)*f,p+Vector2(-54,-140)*f]),sunlit)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-54,-175)*f,p+Vector2(-36,-198)*f,p+Vector2(-26,-140)*f,p+Vector2(-54,-140)*f]),shadow)
	# Characteristic compact tent-like dome roof with cross.
	draw_colored_polygon(PackedVector2Array([p+Vector2(-64,-198)*f,p+Vector2(0,-242)*f,p+Vector2(64,-198)*f]),roof)
	draw_rect(Rect2(p+Vector2(-3,-265)*f,Vector2(6,29)*f),Color("#4f5146"))
	draw_rect(Rect2(p+Vector2(-14,-255)*f,Vector2(28,5)*f),Color("#4f5146"))
	# Narrow blind arches and small carved stone window apertures.
	for i in range(3):
		var xx: float = x + (-67.0 + float(i)*67.0) * f
		draw_rect(Rect2(xx-5.0*f, location_y-93.0*f,10.0*f,30.0*f),Color("#5a584d"))
		draw_arc(Vector2(xx, location_y-93.0*f),5.0*f,PI,TAU,8,Color("#d3bb95",0.7),1.4*f)
	for i in range(2):
		var xx: float = x + (-22.0 + float(i)*44.0)*f
		draw_rect(Rect2(xx-3.0*f,location_y-182.0*f,6.0*f,15.0*f),Color("#5d5b4e"))
	# Entrance and eastern relief band: carved detail at human scale.
	draw_rect(Rect2(p+Vector2(-12,-45)*f,Vector2(24,45)*f),Color("#45473e"))
	draw_line(p+Vector2(-104,-118)*f,p+Vector2(104,-118)*f,Color("#e0c69d",0.60),2.0*f)
	for i in range(8):
		var xx: float = x + (-96.0 + float(i)*28.0)*f
		draw_line(Vector2(xx,location_y-114*f),Vector2(xx+7*f,location_y-109*f),Color("#766e5d",0.65),1.0*f)

# Silhouette set dressing unique to every sub-area (purely decorative).
func _draw_local_landmarks() -> void:
	match area_index:
		0:
			# River overlook, roadside stone crosses, small pilgrim shelter.
			_draw_arch(970.0, 650.0, 1.0)
			_draw_cross(2170.0, 648.0, 0.7)
			_draw_cross(4500.0, 648.0, 0.55)
		1:
			# Ancient stair procession: stone arcs and ascending retaining walls.
			for i in range(6):
				_draw_arch(1040.0+float(i)*990.0,_pilgrim_ground_at(1040.0+float(i)*990.0),0.7+float(i%2)*0.2)
			_draw_cross(5900.0,_pilgrim_ground_at(5900.0),0.8)
		2:
			# Windswept gorge: long lean trees, exposed roots, cliff shrines.
			for i in range(13):
				var x: float = 550.0+float(i)*525.0
				draw_line(Vector2(x,648.0),Vector2(x-34.0,510.0),Color("#444e42"),7.0)
				draw_circle(Vector2(x-55.0,510.0),38.0,Color("#5e7765",0.83))
			_draw_cross(3850.0,648.0,0.6)
		3:
			# Pilgrim arches rise together with the climb.
			for i in range(5):
				var x: float = 1190.0 + float(i)*1450.0
				_draw_arch(x,_ascent_ground_at(x),0.76)
				_draw_cross(x+230.0,_ascent_ground_at(x+230.0),0.48)
		4:
			# Stone perimeter and entrance procession leading to the monastery.
			for i in range(9):
				var x: float = 600.0+float(i)*835.0
				draw_rect(Rect2(x,547.0,14.0,103.0),Color("#817b66"))
				draw_rect(Rect2(x-13.0,538.0,40.0,14.0),Color("#b2a081"))
			_draw_arch(7140.0,650.0,1.35)
			_draw_cross(7520.0,648.0,1.2)

func _draw_cross(x: float, y: float, size: float) -> void:
	draw_rect(Rect2(x-7.0*size,y-89.0*size,14.0*size,89.0*size),Color("#a59a7d"))
	draw_rect(Rect2(x-29.0*size,y-72.0*size,58.0*size,11.0*size),Color("#c2b292"))
	draw_rect(Rect2(x-33.0*size,y-9.0*size,66.0*size,9.0*size),Color("#695f4e"))

func _draw_arch(x: float, y: float, size: float) -> void:
	var stone := Color("#787463")
	var lit := Color("#b6a687")
	draw_rect(Rect2(x-85.0*size,y-140.0*size,27.0*size,140.0*size),stone)
	draw_rect(Rect2(x+58.0*size,y-140.0*size,27.0*size,140.0*size),stone)
	draw_rect(Rect2(x-85.0*size,y-153.0*size,170.0*size,23.0*size),lit)
	draw_rect(Rect2(x-94.0*size,y-160.0*size,188.0*size,11.0*size),stone)
