extends Node2D

## Final Jvari encounter: two coordinated Wardens guard the northern pass.
## Clearing both awards score and permanently opens the road to Zhinvali.

const BOSS_SCENE := preload("res://scenes/enemies/jvari_twin_warden.tscn")
const CLEAR_SAVE_PATH := "user://jvari_pass_wardens.json"
const ARENA_WIDTH: float = 4600.0
const GROUND_Y: float = 650.0
const BOSS_Y: float = 606.0
const LEFT_BOSS_X: float = 1370.0
const RIGHT_BOSS_X: float = 3230.0
const FIGHT_TRIGGER_X: float = 690.0

@export var completion_score_reward: int = 150

var _player: CharacterBody2D
var _bosses: Array[Node] = []
var _defeated_ids: Dictionary = {}
var _fight_started: bool = false
var _fight_won: bool = false
var _active_attacker: Node
var _initiative_slot: int = 0
var _initiative_delay: float = 0.0
var _guard_break_grace: float = 0.0
var _north_gate: StaticBody2D
var _exit_to_zhinvali: Area2D

var _hud_layer: CanvasLayer
var _boss_panel: VBoxContainer
var _left_bar: ProgressBar
var _right_bar: ProgressBar
var _message_label: Label


func _ready() -> void:
	_player = get_node_or_null("Player") as CharacterBody2D
	_build_arena_collision()
	_exit_to_zhinvali = get_node_or_null("ToZhinvali") as Area2D
	_build_boss_hud()

	if _load_clear_state():
		_fight_started = true
		_fight_won = true
		_unlock_northern_gate(false)
		_show_message("THE NORTHERN PASS IS OPEN", 2.5)
	else:
		_lock_northern_gate()
		_spawn_bosses()

	var world: Node = get_node_or_null("/root/WorldState")
	if world != null and world.has_method("enter_location"):
		world.call("enter_location", "jvari")
	queue_redraw()


func _process(delta: float) -> void:
	_initiative_delay = maxf(0.0, _initiative_delay - delta)
	_guard_break_grace = maxf(0.0, _guard_break_grace - delta)

	if not _fight_started and not _fight_won and is_instance_valid(_player):
		if _player.global_position.x >= FIGHT_TRIGGER_X:
			_start_fight()

	_update_boss_hud()


func camera_bounds() -> Rect2i:
	return Rect2i(0, -300, roundi(ARENA_WIDTH), 1120)


func _build_arena_collision() -> void:
	_make_solid("ArenaGround", Vector2(ARENA_WIDTH * 0.5, GROUND_Y + 100.0), Vector2(ARENA_WIDTH, 200.0))
	_make_solid("WestBoundary", Vector2(-16.0, 300.0), Vector2(32.0, 1100.0))
	_make_solid("EastBoundary", Vector2(ARENA_WIDTH + 16.0, 300.0), Vector2(32.0, 1100.0))

	# Two broad one-way stone platforms create deliberate vertical escape routes.
	_make_solid("LeftCombatPlatform", Vector2(660.0, 515.0), Vector2(470.0, 24.0), true)
	_make_solid("RightCombatPlatform", Vector2(3940.0, 515.0), Vector2(470.0, 24.0), true)

	# A low center dais breaks up the flat floor without blocking movement.
	_make_solid("CenterDais", Vector2(2300.0, 618.0), Vector2(360.0, 64.0))


func _make_solid(body_name: String, center: Vector2, size: Vector2, one_way: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
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
	return body


func _spawn_bosses() -> void:
	_spawn_boss(LEFT_BOSS_X, 0)
	_spawn_boss(RIGHT_BOSS_X, 1)


func _spawn_boss(x: float, slot: int) -> void:
	var boss := BOSS_SCENE.instantiate() as CharacterBody2D
	boss.position = Vector2(x, BOSS_Y)
	boss.set("boss_slot", slot)
	boss.set("difficulty", 3)
	boss.add_to_group("jvari_pass_warden")
	add_child(boss)
	if boss.has_method("set_boss_controller"):
		boss.call("set_boss_controller", self)
	if boss.has_method("set_boss_active"):
		boss.call("set_boss_active", false)
	_bosses.append(boss)


func _start_fight() -> void:
	_fight_started = true
	_initiative_slot = 0 if _distance_to_player(_boss_at_slot(0)) <= _distance_to_player(_boss_at_slot(1)) else 1
	for boss: Node in _bosses:
		if is_instance_valid(boss) and boss.has_method("set_boss_active"):
			boss.call("set_boss_active", true)
	_boss_panel.visible = true
	_show_message("WARDENS OF THE NORTHERN PASS", 2.0)


func can_boss_request_attack(boss: Node) -> bool:
	if not _fight_started or _fight_won or not is_instance_valid(boss):
		return false
	if _initiative_delay > 0.0 or _guard_break_grace > 0.0:
		return false
	if is_instance_valid(_active_attacker) and _active_attacker != boss:
		return false
	return int(boss.get("boss_slot")) == _initiative_slot


func request_boss_attack(boss: Node) -> bool:
	if not can_boss_request_attack(boss):
		return false
	_active_attacker = boss
	return true


func release_boss_attack(boss: Node) -> void:
	if _active_attacker != boss:
		return
	_active_attacker = null
	_initiative_slot = _choose_next_initiative(int(boss.get("boss_slot")))
	_initiative_delay = 0.20


func _choose_next_initiative(previous_slot: int) -> int:
	# Do not hand the attack turn to a twin who is still far across the arena.
	# The nearby Warden keeps pressure while the partner shield-walks inward.
	# Once both are engaged, the partner is preferred and the twins alternate.
	var partner_slot := 1 - previous_slot
	var previous := _boss_at_slot(previous_slot)
	var partner := _boss_at_slot(partner_slot)
	if not is_instance_valid(previous):
		return partner_slot
	if not is_instance_valid(partner):
		return previous_slot
	var previous_distance := _distance_to_player(previous)
	var partner_distance := _distance_to_player(partner)
	if partner_distance <= 390.0 or partner_distance <= previous_distance + 110.0:
		return partner_slot
	return previous_slot


func boss_guard_broken(boss: Node) -> void:
	# When one guard breaks, the partner waits instead of stealing the punish window.
	if _active_attacker == boss:
		_active_attacker = null
	_guard_break_grace = 0.78
	_initiative_delay = maxf(_initiative_delay, 0.78)


func boss_defeated(boss: Node) -> void:
	if boss == null:
		return
	_defeated_ids[boss.get_instance_id()] = true
	if _active_attacker == boss:
		_active_attacker = null

	# The remaining Warden receives initiative after a short reset rather than
	# attacking immediately during the death animation.
	_initiative_delay = 0.75
	var slot := int(boss.get("boss_slot"))
	_initiative_slot = 1 - slot

	if _defeated_ids.size() >= 2:
		_complete_fight()


func _complete_fight() -> void:
	if _fight_won:
		return
	_fight_won = true
	_active_attacker = null
	_save_clear_state()

	if is_instance_valid(_player) and _player.has_method("add_score"):
		_player.call("add_score", completion_score_reward)

	_unlock_northern_gate(true)
	_boss_panel.visible = false
	_show_message("PASS CLEARED  +%d SCORE\nROAD TO ZHINVALI OPEN" % completion_score_reward, 4.2)


func _lock_northern_gate() -> void:
	if _north_gate == null:
		_north_gate = _make_solid("NorthernGate", Vector2(4385.0, 530.0), Vector2(46.0, 240.0))
	if is_instance_valid(_exit_to_zhinvali):
		_exit_to_zhinvali.monitoring = false
		_exit_to_zhinvali.monitorable = false


func _unlock_northern_gate(redraw: bool = true) -> void:
	if is_instance_valid(_north_gate):
		_north_gate.queue_free()
	_north_gate = null
	if is_instance_valid(_exit_to_zhinvali):
		_exit_to_zhinvali.monitoring = true
		_exit_to_zhinvali.monitorable = false
	if redraw:
		queue_redraw()


func _boss_at_slot(slot: int) -> Node:
	for boss: Node in _bosses:
		if is_instance_valid(boss) and int(boss.get("boss_slot")) == slot:
			return boss
	return null


func _distance_to_player(boss: Node) -> float:
	if not is_instance_valid(_player) or not is_instance_valid(boss):
		return INF
	return absf(_player.global_position.x - (boss as Node2D).global_position.x)


func _build_boss_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 9
	add_child(_hud_layer)

	_boss_panel = VBoxContainer.new()
	_boss_panel.anchor_left = 0.5
	_boss_panel.anchor_right = 0.5
	_boss_panel.offset_left = -285.0
	_boss_panel.offset_right = 285.0
	_boss_panel.offset_top = 32.0
	_boss_panel.offset_bottom = 132.0
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.add_theme_constant_override("separation", 5)
	_boss_panel.visible = false
	_hud_layer.add_child(_boss_panel)

	var title := Label.new()
	title.text = "WARDENS OF THE NORTHERN PASS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#ead9b2"))
	title.add_theme_color_override("font_outline_color", Color("#252b27"))
	title.add_theme_constant_override("outline_size", 5)
	_boss_panel.add_child(title)

	_left_bar = _make_boss_bar("WEST WARDEN")
	_right_bar = _make_boss_bar("EAST WARDEN")

	_message_label = Label.new()
	_message_label.anchor_left = 0.5
	_message_label.anchor_right = 0.5
	_message_label.offset_left = -330.0
	_message_label.offset_right = 330.0
	_message_label.offset_top = 155.0
	_message_label.offset_bottom = 235.0
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 21)
	_message_label.add_theme_color_override("font_color", Color("#f2dfb4"))
	_message_label.add_theme_color_override("font_outline_color", Color("#242b27"))
	_message_label.add_theme_constant_override("outline_size", 6)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_label.visible = false
	_hud_layer.add_child(_message_label)


func _make_boss_bar(label_text: String) -> ProgressBar:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_boss_panel.add_child(row)
	var label := Label.new()
	label.custom_minimum_size = Vector2(112.0, 18.0)
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#d5c7a7"))
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(410.0, 15.0)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	row.add_child(bar)
	return bar


func _update_boss_hud() -> void:
	if _left_bar == null or _right_bar == null:
		return
	_update_one_bar(_left_bar, _boss_at_slot(0))
	_update_one_bar(_right_bar, _boss_at_slot(1))


func _update_one_bar(bar: ProgressBar, boss: Node) -> void:
	if not is_instance_valid(boss):
		bar.value = 0.0
		return
	var max_hp := maxf(1.0, float(boss.get("max_health")))
	bar.value = clampf(float(boss.get("health")) / max_hp * 100.0, 0.0, 100.0)


func _show_message(text: String, seconds: float) -> void:
	if _message_label == null:
		return
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_label.visible = true
	var tween := create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(_message_label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(Callable(self, "_hide_message"))


func _hide_message() -> void:
	if _message_label != null:
		_message_label.visible = false


func _load_clear_state() -> bool:
	if not FileAccess.file_exists(CLEAR_SAVE_PATH):
		return false
	var file := FileAccess.open(CLEAR_SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed is Dictionary and bool((parsed as Dictionary).get("cleared", false))


func _save_clear_state() -> void:
	var file := FileAccess.open(CLEAR_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"cleared": true}))
	file.close()


func _draw() -> void:
	# Warm highland sky.
	for i in range(18):
		var t := float(i) / 17.0
		var color := Color("#ddd1b6").lerp(Color("#a6aa95"), t)
		draw_rect(Rect2(0.0, -320.0 + float(i) * 54.0, ARENA_WIDTH, 55.0), color)

	# Layered distant Caucasus ridges.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 330), Vector2(430, 60), Vector2(850, 310), Vector2(1320, 5), Vector2(1760, 320),
		Vector2(2210, 85), Vector2(2680, 305), Vector2(3160, 25), Vector2(3650, 300), Vector2(4140, 92),
		Vector2(4600, 305), Vector2(4600, 650), Vector2(0, 650)
	]), Color("#778071"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 430), Vector2(520, 220), Vector2(980, 390), Vector2(1530, 175), Vector2(2070, 405),
		Vector2(2540, 210), Vector2(3060, 400), Vector2(3570, 190), Vector2(4140, 390), Vector2(4600, 245),
		Vector2(4600, 650), Vector2(0, 650)
	]), Color("#5d675d"))

	# Stone fighting court and paving.
	draw_rect(Rect2(0.0, GROUND_Y, ARENA_WIDTH, 210.0), Color("#5a5549"))
	for x in range(0, 4600, 115):
		draw_line(Vector2(float(x), 656.0), Vector2(float(x + 72), 722.0), Color("#77705e", 0.58), 2.0)
	for x in range(50, 4600, 160):
		draw_line(Vector2(float(x), 682.0), Vector2(float(x + 105), 682.0), Color("#90836b", 0.45), 2.0)

	# Left and right jump platforms, visibly supported by old masonry.
	_draw_platform_visual(Vector2(660.0, 503.0), 470.0)
	_draw_platform_visual(Vector2(3940.0, 503.0), 470.0)

	# Center dais.
	draw_colored_polygon(PackedVector2Array([
		Vector2(2120, 650), Vector2(2150, 586), Vector2(2450, 586), Vector2(2480, 650)
	]), Color("#77705f"))
	draw_line(Vector2(2150, 586), Vector2(2450, 586), Color("#c8b795"), 4.0)

	# Weathered side towers frame the arena without becoming collision clutter.
	_draw_watch_pier(235.0, 650.0, 155.0)
	_draw_watch_pier(4365.0, 650.0, 172.0)

	if not _fight_won:
		# Closed northern gate.
		draw_rect(Rect2(4364.0, 410.0, 42.0, 240.0), Color("#2f302b"))
		for y in range(425, 640, 34):
			draw_line(Vector2(4368, float(y)), Vector2(4402, float(y)), Color("#8e7a58"), 3.0)
	else:
		# Open path beyond the gate.
		draw_colored_polygon(PackedVector2Array([
			Vector2(4370, 650), Vector2(4470, 565), Vector2(4600, 555), Vector2(4600, 650)
		]), Color("#8d826d"))


func _draw_platform_visual(center: Vector2, width: float) -> void:
	var left := center.x - width * 0.5
	var right := center.x + width * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, center.y), Vector2(right, center.y), Vector2(right - 44.0, GROUND_Y), Vector2(left + 50.0, GROUND_Y)
	]), Color("#686457"))
	draw_line(Vector2(left, center.y), Vector2(right, center.y), Color("#d2c09b"), 5.0)
	for x in range(int(left + 35.0), int(right - 20.0), 62):
		draw_line(Vector2(float(x), center.y + 10.0), Vector2(float(x + 18), center.y + 49.0), Color("#484b43", 0.65), 2.0)


func _draw_watch_pier(x: float, base_y: float, height: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 48.0, base_y), Vector2(x - 38.0, base_y - height), Vector2(x + 37.0, base_y - height - 12.0),
		Vector2(x + 51.0, base_y)
	]), Color("#5c5b50"))
	for y in range(int(base_y - height + 22.0), int(base_y - 18.0), 32):
		draw_line(Vector2(x - 33.0, float(y)), Vector2(x + 40.0, float(y) + 5.0), Color("#8f8773", 0.50), 2.0)
