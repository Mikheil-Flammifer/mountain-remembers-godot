extends Node2D
## Playable Jvari church interior: Georgian cross-in-square-inspired stonework,
## two interactive NPCs and a safe return doorway. Uses existing travel manager.

const FLOOR_Y: float = 650.0
const WIDTH: float = 2200.0
const INTERACTION_RADIUS: float = 134.0
const MONK_X: float = 790.0
const PILGRIM_X: float = 1510.0

var _player: CharacterBody2D
var _nearby: String = ""
var _active_npc: String = ""
var _dialogue_index: int = 0
var _dialogue_open: bool = false
var _player_physics_before_dialogue: bool = true
var _prompt: Label
var _dialogue_panel: PanelContainer
var _speaker_label: Label
var _dialogue_label: Label
var _clock: float = 0.0

const MONK_LINES: Array[Dictionary] = [
	{"speaker": "Elder Monk", "text": "Peace to you, Xizane. Few climb to Jvari without a question weighing on them."},
	{"speaker": "Xizane", "text": "I am searching for Samdzivari, my sister. She went into the mountains alone."},
	{"speaker": "Elder Monk", "text": "I met a traveller who spoke of a young woman crossing the northern passes. She would not give her name."},
	{"speaker": "Elder Monk", "text": "A wounded heart may seek solitude, but do not mistake solitude for death. Follow the mountain road."}
]
const PILGRIM_LINES: Array[Dictionary] = [
	{"speaker": "Highland Pilgrim", "text": "The river below is gentle today. The wind beyond the church is not."},
	{"speaker": "Xizane", "text": "Did a woman travel here, without companions?"},
	{"speaker": "Highland Pilgrim", "text": "I heard of one who refused the road home and took shelter among the highlanders. The tale came from beyond the ravine."},
	{"speaker": "Highland Pilgrim", "text": "Keep to the ravine path after Jvari. A true answer may hurt more than uncertainty."}
]

func _ready() -> void:
	_player = get_node_or_null("Player") as CharacterBody2D
	_build_collision()
	_build_dialogue_hud()
	var world: Node = get_node_or_null("/root/WorldState")
	if world != null and world.has_method("enter_location"):
		world.call("enter_location", "jvari")
	queue_redraw()

func camera_bounds() -> Rect2i:
	return Rect2i(0, -430, int(WIDTH), 1250)

func _physics_process(delta: float) -> void:
	_clock += delta
	if not is_instance_valid(_player):
		return
	if _dialogue_open:
		_prompt.visible = false
		return
	var feet: Vector2 = _player.global_position + Vector2(0.0, 47.0)
	var nearest: String = ""
	if feet.distance_to(Vector2(MONK_X, FLOOR_Y)) < INTERACTION_RADIUS:
		nearest = "monk"
	elif feet.distance_to(Vector2(PILGRIM_X, FLOOR_Y)) < INTERACTION_RADIUS:
		nearest = "pilgrim"
	_nearby = nearest
	_prompt.visible = not nearest.is_empty()
	if nearest == "monk":
		_prompt.text = "E  -  Speak with Elder Monk"
	elif nearest == "pilgrim":
		_prompt.text = "E  -  Speak with Pilgrim"

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	var interact: bool = (
		key.physical_keycode == KEY_E
		or key.keycode == KEY_E
		or key.is_action_pressed("talk")
	)
	if _dialogue_open:
		if interact or key.keycode == KEY_SPACE or key.keycode == KEY_ENTER:
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_ESCAPE:
			_close_dialogue()
			get_viewport().set_input_as_handled()
	elif interact and not _nearby.is_empty():
		_start_dialogue(_nearby)
		get_viewport().set_input_as_handled()

func _start_dialogue(npc: String) -> void:
	_active_npc = npc
	_dialogue_index = 0
	_dialogue_open = true
	_dialogue_panel.visible = true
	_prompt.visible = false
	# Dialogue should not use set_resting(): that makes Xizane SIT.
	# Pause movement physics only; _process still animates a standing idle.
	if is_instance_valid(_player):
		_player_physics_before_dialogue = _player.is_physics_processing()
		_player.velocity = Vector2.ZERO
		_player.set_physics_process(false)
	_show_line()

func _advance_dialogue() -> void:
	_dialogue_index += 1
	var lines: Array[Dictionary] = MONK_LINES if _active_npc == "monk" else PILGRIM_LINES
	if _dialogue_index >= lines.size():
		_close_dialogue()
	else:
		_show_line()

func _show_line() -> void:
	var lines: Array[Dictionary] = MONK_LINES if _active_npc == "monk" else PILGRIM_LINES
	var line: Dictionary = lines[_dialogue_index]
	_speaker_label.text = str(line["speaker"])
	_dialogue_label.text = str(line["text"]) + "\n\n[E] Continue       [Esc] Close"

func _close_dialogue() -> void:
	_dialogue_open = false
	_dialogue_panel.visible = false
	if is_instance_valid(_player):
		_player.velocity = Vector2.ZERO
		_player.set_physics_process(_player_physics_before_dialogue)

func _build_dialogue_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	layer.name = "ChurchStoryUI"
	add_child(layer)
	_prompt = Label.new()
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 0.82
	_prompt.anchor_bottom = 0.82
	_prompt.offset_left = -230.0
	_prompt.offset_right = 230.0
	_prompt.offset_top = -40.0
	_prompt.offset_bottom = 0.0
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_font_size_override("font_size", 19)
	_prompt.add_theme_color_override("font_color", Color("#f2dfb1"))
	_prompt.add_theme_color_override("font_outline_color", Color("#242a29"))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.visible = false
	layer.add_child(_prompt)
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.anchor_left = 0.5
	_dialogue_panel.anchor_right = 0.5
	_dialogue_panel.anchor_top = 0.75
	_dialogue_panel.anchor_bottom = 0.75
	_dialogue_panel.offset_left = -385.0
	_dialogue_panel.offset_right = 385.0
	_dialogue_panel.offset_top = -40.0
	_dialogue_panel.offset_bottom = 150.0
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#252b2a", 0.96)
	style.border_color = Color("#bda87f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(17)
	_dialogue_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	_dialogue_panel.add_child(box)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 21)
	_speaker_label.add_theme_color_override("font_color", Color("#e1c78e"))
	box.add_child(_speaker_label)
	_dialogue_label = Label.new()
	_dialogue_label.add_theme_font_size_override("font_size", 16)
	_dialogue_label.add_theme_color_override("font_color", Color("#f0e8d4"))
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_dialogue_label)
	layer.add_child(_dialogue_panel)
	_dialogue_panel.visible = false

func _build_collision() -> void:
	_add_wall("StoneFloor", Vector2(WIDTH * 0.5, 750.0), Vector2(WIDTH, 200.0))
	_add_wall("WestWall", Vector2(-20.0, 130.0), Vector2(40.0, 1200.0))
	_add_wall("EastWall", Vector2(WIDTH + 20.0, 130.0), Vector2(40.0, 1200.0))

func _add_wall(wall_name: String, at: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = at
	wall.collision_layer = 1
	wall.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)

func _draw() -> void:
	# Historically inspired, game-friendly Jvari interior: warm candlelight,
	# massive stone vaults, central wooden cross, icons, and a sand-filled candle tray.
	var bg_top := Color("#46362b")
	var bg_bottom := Color("#6a5240")
	for i in range(18):
		var t: float = float(i) / 17.0
		draw_rect(Rect2(0.0, -470.0 + float(i) * 66.0, WIDTH, 68.0), bg_top.lerp(bg_bottom, t))

	# Main stone shell.
	draw_rect(Rect2(0.0, -390.0, WIDTH, 1015.0), Color("#6e5645"))
	for bay in range(5):
		var x: float = 116.0 + float(bay) * 404.0
		_draw_stone_pier(x, 56.0, 112.0, 550.0)

	# Side and central arches.
	_draw_vault_bay(360.0, -120.0, 180.0, 520.0)
	_draw_vault_bay(780.0, -140.0, 210.0, 560.0)
	_draw_vault_bay(1170.0, -154.0, 230.0, 590.0)
	_draw_vault_bay(1560.0, -136.0, 205.0, 555.0)
	_draw_vault_bay(1920.0, -115.0, 170.0, 510.0)

	# High drum / apse emphasis in the middle.
	draw_arc(Vector2(1110.0, -25.0), 285.0, PI, TAU, 34, Color("#8f6e53"), 44.0)
	draw_arc(Vector2(1110.0, -18.0), 248.0, PI, TAU, 34, Color("#5a4436"), 26.0)

	# Tall central window with light beam.
	_draw_window_with_ray(Vector2(1110.0, -210.0), 40.0, 128.0, 465.0)
	# Three altar windows.
	for i in range(3):
		var wx: float = 978.0 + float(i) * 114.0
		_draw_slim_window(wx, 248.0, 23.0, 82.0)

	# Floor.
	draw_rect(Rect2(0.0, 560.0, WIDTH, 270.0), Color("#655343"))
	draw_rect(Rect2(0.0, 560.0, WIDTH, 22.0), Color("#8a6d55"))
	for row in range(6):
		var y: float = 590.0 + float(row) * 37.0
		draw_line(Vector2(0.0, y), Vector2(WIDTH, y), Color("#40352c", 0.42), 1.1)
	for col in range(30):
		var x: float = float(col) * 76.0
		draw_line(Vector2(x, 560.0), Vector2(x + 16.0, 830.0), Color("#8e765f", 0.20), 1.0)

	# Carpet runner.
	draw_rect(Rect2(755.0, 660.0, 430.0, 138.0), Color("#6f3022"))
	draw_rect(Rect2(773.0, 676.0, 394.0, 106.0), Color("#8e5038"))
	for i in range(7):
		var cx: float = 806.0 + float(i) * 53.0
		draw_rect(Rect2(cx, 699.0, 22.0, 22.0), Color("#c39f70"))
		draw_rect(Rect2(cx + 8.0, 741.0, 6.0, 22.0), Color("#c39f70"))
		draw_rect(Rect2(cx - 2.0, 748.0, 22.0, 6.0), Color("#c39f70"))

	# Iconostasis / red curtain backdrop.
	draw_rect(Rect2(824.0, 358.0, 578.0, 132.0), Color("#6e3b2a"))
	draw_rect(Rect2(839.0, 372.0, 548.0, 102.0), Color("#8e4a32"))
	for i in range(4):
		var x: float = 876.0 + float(i) * 118.0
		draw_rect(Rect2(x, 387.0, 60.0, 78.0), Color("#9f1322"))
		_draw_small_icon(Rect2(x + 7.0, 395.0, 46.0, 58.0))
	for post in range(6):
		var px: float = 845.0 + float(post) * 106.0
		draw_rect(Rect2(px, 358.0, 10.0, 132.0), Color("#5b3928"))

	# Altar stone base and cloth.
	draw_rect(Rect2(912.0, 506.0, 396.0, 90.0), Color("#766253"))
	draw_rect(Rect2(936.0, 485.0, 350.0, 38.0), Color("#d5c3a7"))
	for i in range(16):
		var tx: float = 944.0 + float(i) * 21.0
		draw_line(Vector2(tx, 520.0), Vector2(tx, 530.0), Color("#ac9574"), 1.0)

	# Central carved wooden cross.
	var cross_col := Color("#c89b54")
	draw_rect(Rect2(1076.0, 246.0, 28.0, 286.0), cross_col)
	draw_rect(Rect2(980.0, 340.0, 220.0, 28.0), cross_col)
	for i in range(10):
		var y: float = 260.0 + float(i) * 25.0
		draw_line(Vector2(1080.0, y), Vector2(1100.0, y), Color("#e2bb73", 0.50), 1.4)
	for i in range(7):
		var x: float = 994.0 + float(i) * 29.0
		draw_line(Vector2(x, 344.0), Vector2(x, 364.0), Color("#e2bb73", 0.50), 1.2)

	# Foreground sand-filled candle tray.
	_draw_candle_tray(Vector2(420.0, 700.0))

	# Side icon stands and candles.
	_draw_icon_stand(Vector2(195.0, 508.0), 92.0)
	_draw_icon_stand(Vector2(575.0, 520.0), 78.0)
	_draw_icon_stand(Vector2(1628.0, 514.0), 84.0)
	_draw_icon_stand(Vector2(1945.0, 500.0), 92.0)
	_draw_small_candle_stand(Vector2(260.0, 566.0), 7)
	_draw_small_candle_stand(Vector2(1725.0, 565.0), 6)

	# Rope barrier around the altar area.
	for x in [880.0, 965.0, 1250.0, 1338.0]:
		draw_rect(Rect2(x, 535.0, 5.0, 52.0), Color("#2d2724"))
	for seg in [[883.0,968.0],[968.0,1254.0],[1254.0,1341.0]]:
		draw_line(Vector2(seg[0], 553.0), Vector2(seg[1], 559.0), Color("#3d332d"), 2.0)

	# Wall torches.
	_draw_wall_torch(Vector2(148.0, 354.0))
	_draw_wall_torch(Vector2(2062.0, 360.0))

	# Entry door and carved cross by the west wall.
	draw_rect(Rect2(40.0, 430.0, 84.0, 130.0), Color("#342920"))
	draw_rect(Rect2(32.0, 420.0, 100.0, 14.0), Color("#ab906d"))
	draw_line(Vector2(178.0, 307.0), Vector2(178.0, 368.0), Color("#b99a70"), 6.0)
	draw_line(Vector2(152.0, 329.0), Vector2(204.0, 329.0), Color("#b99a70"), 5.0)
	# NPCs.
	_draw_monk(MONK_X, FLOOR_Y, Color("#403c39"), true)
	_draw_monk(PILGRIM_X, FLOOR_Y, Color("#5a6156"), false)
func _draw_vault_bay(cx: float, top: float, radius: float, height: float) -> void:
	draw_arc(Vector2(cx, top + radius), radius, PI, TAU, 28, Color("#9d7a5f"), 30.0)
	draw_arc(Vector2(cx, top + radius), radius - 20.0, PI, TAU, 28, Color("#5a4335"), 10.0)
	draw_line(Vector2(cx - radius, top + radius), Vector2(cx - radius, top + height), Color("#8b6d54"), 30.0)
	draw_line(Vector2(cx + radius, top + radius), Vector2(cx + radius, top + height), Color("#8b6d54"), 30.0)
	for i in range(4):
		var y: float = top + radius + 58.0 + float(i) * 62.0
		draw_line(Vector2(cx - radius + 16.0, y), Vector2(cx + radius - 16.0, y), Color("#a98768", 0.18), 1.0)

func _draw_stone_pier(x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x, y, w, h), Color("#8b6e56"))
	draw_rect(Rect2(x + 7.0, y + 6.0, w - 14.0, h - 12.0), Color("#a27f61", 0.50))
	for row in range(7):
		var yy: float = y + float(row + 1) * h / 7.0
		draw_line(Vector2(x + 3.0, yy), Vector2(x + w - 3.0, yy), Color("#5c493b", 0.35), 1.0)

func _draw_window_with_ray(center: Vector2, w: float, h: float, beam_h: float) -> void:
	var rect := Rect2(center.x - w * 0.5, center.y, w, h)
	draw_rect(rect, Color("#9e9277"))
	draw_arc(Vector2(center.x, center.y), w * 0.5, PI, TAU, 12, Color("#9e9277"), 4.0)
	draw_rect(Rect2(center.x - (w * 0.28), center.y + 8.0, w * 0.56, h - 18.0), Color("#d9e4f0"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - w * 0.28, center.y + h - 5.0),
		Vector2(center.x + w * 0.28, center.y + h - 5.0),
		Vector2(center.x + 165.0, center.y + beam_h),
		Vector2(center.x - 135.0, center.y + beam_h)
	]), Color("#efe4c4", 0.10))

func _draw_slim_window(x: float, y: float, w: float, h: float) -> void:
	draw_arc(Vector2(x, y), w * 0.5, PI, TAU, 10, Color("#8a8067"), 3.0)
	draw_rect(Rect2(x - w * 0.5, y, w, h), Color("#8a8067"))
	draw_rect(Rect2(x - (w * 0.22), y + 6.0, w * 0.44, h - 12.0), Color("#d5dfeb"))

func _draw_candle_tray(center: Vector2) -> void:
	_draw_filled_ellipse(center, Vector2(150.0, 42.0), Color("#7b5838"))
	_draw_filled_ellipse(center + Vector2(0.0, 2.0), Vector2(140.0, 34.0), Color("#ccb57e"))
	draw_rect(Rect2(center.x - 6.0, center.y + 35.0, 12.0, 54.0), Color("#6c4f34"))
	# Decorative studs / crosses on the tray wall.
	for sx in [-108.0, 0.0, 108.0]:
		for offset in [Vector2.ZERO, Vector2(-8, 0), Vector2(8, 0), Vector2(0, -8), Vector2(0, 8)]:
			draw_circle(center + Vector2(sx, 25.0) + offset, 2.2, Color("#b88b52"))
	# Beeswax candles planted in sand.
	for i in range(17):
		var x: float = center.x - 85.0 + float(i) * 10.0
		var height: float = 42.0 + float((i * 7) % 6) * 10.0
		var y: float = center.y - 6.0 - float(i % 3) * 3.0
		draw_rect(Rect2(x, y - height, 3.2, height), Color("#f0d07f"))
		draw_circle(Vector2(x + 1.6, y - height - 4.0), 4.4, Color("#f4b95e"))
		draw_circle(Vector2(x + 1.6, y - height - 7.0), 1.7, Color("#fff3ba"))
	for i in range(7):
		var x: float = center.x - 10.0 + float(i) * 8.0
		var height: float = 20.0 + float(i % 4) * 6.0
		var y: float = center.y + 1.0
		draw_rect(Rect2(x, y - height, 3.0, height), Color("#efca73"))
		draw_circle(Vector2(x + 1.5, y - height - 4.0), 4.0, Color("#f4b45e"))

func _draw_icon_stand(pos: Vector2, h: float) -> void:
	draw_rect(Rect2(pos.x - 32.0, pos.y - h, 64.0, h), Color("#5a3928"))
	draw_rect(Rect2(pos.x - 28.0, pos.y - h + 6.0, 56.0, h - 12.0), Color("#7a5038"))
	draw_rect(Rect2(pos.x - 22.0, pos.y - h + 14.0, 44.0, 54.0), Color("#d4b06b"))
	draw_rect(Rect2(pos.x - 18.0, pos.y - h + 18.0, 36.0, 46.0), Color("#8b6e4d"))
	draw_circle(Vector2(pos.x, pos.y - h + 37.0), 11.0, Color("#d9c29a"))
	draw_rect(Rect2(pos.x - 8.0, pos.y - h + 49.0, 16.0, 10.0), Color("#b65c40"))
	for i in range(3):
		var yy: float = pos.y - h + 6.0 + float(i) * 5.0
		draw_line(Vector2(pos.x - 18.0, yy), Vector2(pos.x + 18.0, yy), Color("#d8bb82", 0.26), 1.0)

func _draw_small_icon(rect: Rect2) -> void:
	draw_rect(rect, Color("#d4b06b"))
	draw_rect(Rect2(rect.position.x + 4.0, rect.position.y + 4.0, rect.size.x - 8.0, rect.size.y - 8.0), Color("#8a694b"))
	draw_circle(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 18.0), 7.0, Color("#e6d0a0"))
	draw_rect(Rect2(rect.position.x + rect.size.x * 0.5 - 8.0, rect.position.y + 26.0, 16.0, 18.0), Color("#6b2e24"))

func _draw_small_candle_stand(pos: Vector2, candle_count: int) -> void:
	draw_arc(pos, 26.0, 0.0, TAU, 18, Color("#29211d"), 6.0)
	draw_rect(Rect2(pos.x - 2.5, pos.y + 1.0, 5.0, 28.0), Color("#29211d"))
	for i in range(candle_count):
		var x: float = pos.x - 16.0 + float(i) * 5.0
		var h: float = 19.0 + float((i * 7) % 3) * 5.0
		draw_rect(Rect2(x, pos.y - h, 2.2, h), Color("#e2cf9c"))
		draw_circle(Vector2(x + 1.1, pos.y - h - 3.0), 3.0, Color("#efb45d"))

func _draw_wall_torch(pos: Vector2) -> void:
	draw_line(pos, pos + Vector2(18.0, 10.0), Color("#3b3028"), 3.0)
	draw_circle(pos + Vector2(22.0, 12.0), 8.0, Color("#d29448"))
	draw_circle(pos + Vector2(22.0, 6.0), 4.0, Color("#fff2b1"))

func _draw_monk(x: float, base_y: float, cloak: Color, hood: bool) -> void:
	var skin := Color("#c2a589")
	var shadow := Color("#303431")
	draw_colored_polygon(PackedVector2Array([Vector2(x - 25.0, base_y), Vector2(x - 22.0, base_y - 75.0), Vector2(x - 13.0, base_y - 102.0), Vector2(x + 13.0, base_y - 102.0), Vector2(x + 24.0, base_y - 74.0), Vector2(x + 28.0, base_y)]), cloak)
	draw_rect(Rect2(x - 17.0, base_y - 46.0, 35.0, 5.0), Color("#8e7860"))
	draw_circle(Vector2(x, base_y - 108.0), 16.0, shadow)
	draw_circle(Vector2(x, base_y - 106.0), 11.0, skin)
	if hood:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 23.0, base_y - 94.0), Vector2(x - 14.0, base_y - 128.0), Vector2(x + 10.0, base_y - 129.0), Vector2(x + 23.0, base_y - 92.0), Vector2(x + 8.0, base_y - 104.0), Vector2(x, base_y - 119.0), Vector2(x - 8.0, base_y - 104.0)]), shadow)
	else:
		draw_line(Vector2(x + 12.0, base_y - 70.0), Vector2(x + 23.0, base_y), Color("#98856a"), 5.0)

func _draw_filled_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(49):
		var angle: float = TAU * float(i) / 48.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
