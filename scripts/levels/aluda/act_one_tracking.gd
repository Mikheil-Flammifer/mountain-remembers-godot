extends Node2D
## Act 1 tracking section. Story state is owned by this encounter.

const Story = preload("res://scripts/systems/story/act_one_state.gd")
const ALUDA = preload("res://scenes/actors/player/aluda.tscn")
const MESSENGER = preload("res://scenes/visuals/actors/characters/messenger/messenger_visual.tscn")
const RIFLE = preload("res://scripts/levels/aluda/rifle_encounter.gd")
const BROTHER = preload("res://scenes/visuals/actors/characters/mutsal_brother/mutsal_brother_visual.tscn")
const SANATA = preload("res://scenes/visuals/actors/characters/sanata/sanata_visual.tscn")
const DIALOGUE_PANEL = preload("res://scripts/ui/aluda_dialogue_panel.gd")
const SUBAREAS = preload("res://scripts/levels/aluda/act_one_subareas.gd")
const AREA_BANNER = preload("res://scripts/ui/act_one_area_banner.gd")
const FOLD_INVESTIGATION = preload("res://scripts/levels/aluda/shepherds_fold_investigation.gd")
const WIND_TRACKING = preload("res://scripts/levels/aluda/wind_pasture_tracking.gd")
const MUTSAL = preload("res://scenes/visuals/actors/characters/mutsal/mutsal_visual.tscn")
const MUTSAL_DUEL = preload("res://scripts/levels/aluda/act_one_mutsal_duel.gd")
const ACT_TWO_CAMP = preload("res://scenes/levels/aluda/act_two/night_camp.tscn")

var story = Story.new()
var fold_investigation: ShepherdsFoldInvestigation = FOLD_INVESTIGATION.new()
var wind_tracking: WindPastureTracking = WIND_TRACKING.new()
var player: CharacterBody2D
var dialogue_panel: AludaDialoguePanel
var area_banner: ActOneAreaBanner
var current_subarea: int = -1
var prompt: Label
var trail_status: Label
var _marker_time: float = 0.0
var _marker_clock: float = 0.0
var rifle: RifleEncounter
var brother: Node2D
var mutsal: Node2D
var mutsal_duel: ActOneMutsalDuel
var camera: Camera2D
var world_tint: CanvasModulate
var checkpoint_position: Vector2 = Vector2(50, 440)
var highest_subarea: int = 0
var _target_zoom: Vector2 = Vector2(1.6, 1.6)
var _target_tint: Color = Color.WHITE
var _hand_hold: float = 0.0
var _leaving_act_one: bool = false
var _points := [
	{"id": "report", "x": 160.0, "label": "Messenger", "text": "The shepherds were attacked. Raiders took horses, including yours. Follow their trail toward Arkhoti."},
	{"id": "halter", "x": 295.0, "label": "Cut halter", "text": ""},
	{"id": "dogs", "x": 430.0, "label": "Silent sheepdog", "text": ""},
	{"id": "gate", "x": 570.0, "label": "Broken gate", "text": ""},
	{"id": "hoofprints", "x": 750.0, "label": "Hoofprints", "text": ""},
	{"id": "scrape", "x": 900.0, "label": "Scraped slate", "text": ""},
	{"id": "grass", "x": 1060.0, "label": "Bent grass", "text": ""},
	{"id": "ridge", "x": 1160.0, "label": "Read upper ledge", "text": ""},
	{"id": "gully", "x": 1220.0, "label": "Check lower gully", "text": ""},
	{"id": "river", "x": 1400.0, "label": "River detour", "text": "The river stones are wet with fresh prints. The raiders may reach cover while you take this longer path."},
	{"id": "stones", "x": 1720.0, "label": "Wet stones", "text": "Water on the stones shows where the horses crossed."},
	{"id": "birds", "x": 2050.0, "label": "Birdcalls", "text": "Birdcalls echo over the pasture as the dawn light reaches the crags."},
	{"id": "crags", "x": 2400.0, "label": "The crags", "text": "The trail leads into a narrow field of slate. Someone is waiting among the rocks."},
]


func _ready() -> void:
	_build_world()
	_build_hud()
	_update_subarea()


func _build_world() -> void:
	var ground := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4050, 120)
	collision.shape = shape
	ground.position = Vector2(1925, 500)
	ground.add_child(collision)
	add_child(ground)
	# Keep the player on the authored route, including while jumping.
	_add_route_barrier(Vector2(-75, 0), Vector2(40, 1200), false)
	_add_route_barrier(Vector2(3925, 0), Vector2(40, 1200), false)
	# Low stones create short, readable jumps between investigation areas.
	_add_route_barrier(Vector2(635, 426), Vector2(38, 28), true)
	_add_route_barrier(Vector2(1870, 423), Vector2(48, 34), true)
	world_tint = CanvasModulate.new()
	world_tint.name = "Atmosphere"
	world_tint.color = Color.WHITE
	add_child(world_tint)
	player = ALUDA.instantiate()
	player.position = Vector2(50, 440)
	add_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(0, -110)
	camera.zoom = Vector2(1.6, 1.6)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.8
	camera.limit_left = -150
	camera.limit_right = 4010
	player.add_child(camera)
	var messenger: Node2D = MESSENGER.instantiate()
	messenger.position = Vector2(160, 440)
	add_child(messenger)
	var sanata: Node2D = SANATA.instantiate()
	sanata.position = Vector2(1400, 440)
	add_child(sanata)
	brother = BROTHER.instantiate()
	brother.position = Vector2(2820, 440)
	brother.visible = false
	add_child(brother)
	mutsal = MUTSAL.instantiate()
	mutsal.name = "Mutsal"
	mutsal.position = Vector2(3260, 440)
	mutsal.visible = false
	add_child(mutsal)
	mutsal_duel = MUTSAL_DUEL.new()
	mutsal_duel.name = "MutsalDuel"
	add_child(mutsal_duel)
	mutsal_duel.updated.connect(func(speaker: String, line: String): _show_dialogue(speaker, line))
	mutsal_duel.final_exchange_complete.connect(_on_mutsal_final)
	rifle = RIFLE.new()
	add_child(rifle)
	rifle.updated.connect(func(text: String): _show_dialogue("The crags", text))
	rifle.defeated.connect(_on_brother_defeated)
	queue_redraw()


func _add_route_barrier(center: Vector2, size: Vector2, visible_stone: bool) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	if visible_stone:
		var stone := Polygon2D.new()
		stone.polygon = PackedVector2Array([Vector2(-size.x / 2, size.y / 2), Vector2(-size.x / 2, -size.y / 2), Vector2(size.x / 2, -size.y / 2), Vector2(size.x / 2, size.y / 2)])
		stone.color = Color("#717b6d")
		body.add_child(stone)
	add_child(body)


func _build_hud() -> void:
	# Dialogue is a separate presentation component, anchored at the bottom.
	dialogue_panel = DIALOGUE_PANEL.new()
	dialogue_panel.name = "DialoguePanel"
	add_child(dialogue_panel)
	area_banner = AREA_BANNER.new()
	area_banner.name = "AreaBanner"
	add_child(area_banner)

	var layer := CanvasLayer.new()
	layer.name = "ExplorationHUD"
	layer.layer = 5
	add_child(layer)
	var overlay := Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)

	trail_status = Label.new()
	trail_status.name = "TrailStatus"
	trail_status.position = Vector2(24, 20)
	trail_status.size = Vector2(920, 30)
	trail_status.add_theme_font_size_override("font_size", 15)
	trail_status.add_theme_color_override("font_color", Color("#ead7ac"))
	trail_status.add_theme_color_override("font_outline_color", Color("#1c292b"))
	trail_status.add_theme_constant_override("outline_size", 4)
	trail_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(trail_status)

	prompt = Label.new()
	prompt.name = "InteractionHint"
	prompt.anchor_left = 0.18
	prompt.anchor_right = 0.82
	prompt.anchor_top = 1.0
	prompt.anchor_bottom = 1.0
	prompt.offset_top = -59
	prompt.offset_bottom = -24
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color("#f4e7cd"))
	prompt.add_theme_color_override("font_outline_color", Color("#162629"))
	prompt.add_theme_constant_override("outline_size", 5)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(prompt)


func _show_dialogue(speaker: String, text: String) -> void:
	dialogue_panel.show_line(speaker, text)


func _update_subarea() -> void:
	# One continuous level: the region identity is visual and informational.
	if player == null or area_banner == null:
		return
	var next_index: int = SUBAREAS.index_at(player.position.x)
	if next_index == current_subarea:
		return
	current_subarea = next_index
	if current_subarea > highest_subarea:
		highest_subarea = current_subarea
		match current_subarea:
			1: checkpoint_position = Vector2(690, 440)
			2: checkpoint_position = Vector2(1270, 440)
			3: checkpoint_position = Vector2(1960, 440)
	match current_subarea:
		0:
			_target_zoom = Vector2(1.6, 1.6)
			_target_tint = Color.WHITE
		1:
			_target_zoom = Vector2(1.5, 1.5)
			_target_tint = Color("#f6f7ee")
		2:
			_target_zoom = Vector2(1.56, 1.56)
			_target_tint = Color("#e9f3f3")
		3:
			_target_zoom = Vector2(1.44, 1.44)
			_target_tint = Color("#f4e8e3")
	var details: Dictionary = SUBAREAS.region(current_subarea)
	if details.is_empty():
		return
	area_banner.announce(str(details["title"]), str(details["subtitle"]))
	dialogue_panel.set_location(str(details["short_name"]))


func _process(delta: float) -> void:
	if player.position.y > 780.0:
		player.position = checkpoint_position
		player.velocity = Vector2.ZERO
	_update_subarea()
	# The camera and atmospheric tint blend across seamless area boundaries.
	if camera != null:
		camera.zoom = camera.zoom.lerp(_target_zoom, clampf(delta * 1.7, 0.0, 1.0))
	if world_tint != null:
		world_tint.color = world_tint.color.lerp(_target_tint, clampf(delta * 1.35, 0.0, 1.0))
	if mutsal_duel != null:
		mutsal_duel.tick(delta, player.position.x >= 2870.0 and player.position.x <= 2990.0)
	if story.phase == Story.Phase.HAND_DECISION:
		if absf(player.position.x - 3260.0) < 82.0 and Input.is_key_pressed(KEY_H):
			_hand_hold += delta
			if _hand_hold >= 1.4:
				_resolve_hand(Story.HandChoice.CUT)
		else:
			_hand_hold = 0.0
	_marker_time += delta
	_marker_clock += delta
	if _marker_clock >= 0.12:
		_marker_clock = 0.0
		queue_redraw()
	if rifle.active:
		rifle.tick(delta, player.position.x >= 2500.0 and player.position.x <= 2580.0)
	var point := _nearby_point()
	if story.phase in [Story.Phase.MUTSAL_RIFLE, Story.Phase.MUTSAL_COVER]:
		prompt.text = "F — Fire    R — Reload    Shelter at the second boulder"
		if not mutsal_duel.active:
			prompt.text = "R — Retry the duel"
	elif story.phase == Story.Phase.MUTSAL_FINAL:
		prompt.text = "Mutsal's final exchange..."
	elif story.phase == Story.Phase.HAND_DECISION:
		if absf(player.position.x - 3260.0) < 82.0:
			prompt.text = "Hold H to follow the old custom  ·  %.1f / 1.4 sec" % minf(_hand_hold, 1.4)
		elif absf(player.position.x - 3460.0) < 80.0:
			prompt.text = "E — Cover Mutsal and spare his hand"
		else:
			prompt.text = "Make your choice: the body or the path beyond"
	elif story.phase == Story.Phase.COMPLETE:
		prompt.text = "E — Leave for the night camp" if absf(player.position.x - 3750.0) < 92.0 else "Follow the stone road to the night camp"
	elif rifle.active:
		if player.position.x >= 2500.0 and player.position.x <= 2580.0:
			prompt.text = "BEHIND COVER    F — Fire    R — Reload"
		else:
			prompt.text = "F — Fire    R — Reload    Seek shelter behind the low rock"
	elif not point.is_empty():
		prompt.text = "E — " + str(point.get("label", ""))
	else:
		prompt.text = "A / D — Move    Space — Jump"
	prompt.visible = not dialogue_panel.is_open
	if story.phase == Story.Phase.RAID_REPORT:
		trail_status.text = "ACT I — THE RAID  |  Speak to the messenger"
	elif story.phase == Story.Phase.TRACKING:
		if current_subarea == 0:
			trail_status.text = "TRAIL SIGNS  %d / 5    |    SHEEPFOLD  %d / 3" % [
				story.trail_clues.size(), fold_investigation.evidence_count()
			]
		elif current_subarea == 1:
			var route_status: String = "RIDGE FOUND" if wind_tracking.route_confirmed else "READ THE TRACKS"
			trail_status.text = "TRAIL SIGNS  %d / 5    |    PASTURE  %d / 3    |    %s" % [
				story.trail_clues.size(), wind_tracking.clue_count(), route_status
			]
		else:
			trail_status.text = "TRAIL SIGNS  %d / 5  (optional)" % story.trail_clues.size()
	elif story.phase == Story.Phase.COMPLETE:
		trail_status.text = "ACT I — COMPLETE   |   Road to the night camp"
	else:
		trail_status.text = "ACT I — THE CRAGS"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# ENTER reads/finishes the dialogue; E remains the world-interact key.
		var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key == KEY_ENTER or key == KEY_KP_ENTER:
			if dialogue_panel.is_open:
				dialogue_panel.advance()
				get_viewport().set_input_as_handled()
				return
		elif key == KEY_ESCAPE and dialogue_panel.is_open:
			dialogue_panel.close()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F or event.keycode == KEY_F:
			if story.phase in [Story.Phase.MUTSAL_RIFLE, Story.Phase.MUTSAL_COVER]:
				mutsal_duel.attempt_shot(player.position.x >= 3000.0 and player.position.x <= 3170.0 and player.facing > 0.0)
			else:
				rifle.fire(player.position.x > 2580.0 and player.position.x < 2820.0 and player.facing > 0.0)
			return
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			if story.phase in [Story.Phase.MUTSAL_RIFLE, Story.Phase.MUTSAL_COVER]:
				if not mutsal_duel.active:
					player.position = Vector2(2930, 440)
					mutsal_duel.retry()
				else:
					mutsal_duel.reload_next()
				return
			if story.phase == Story.Phase.BROTHER_FIGHT and not rifle.active:
				player.position = Vector2(2510, 440)
				rifle.player_health = 2
				rifle.enemy_health = 1
				rifle.loaded = true
				rifle.reload_step = 0
				rifle.enemy_timer = rifle.ENEMY_FIRE_INTERVAL + wind_tracking.approach_bonus_seconds()
				rifle.start()
			else:
				rifle.reload_next()
			return
	if not event.is_action_pressed("talk") or event.is_echo():
		return
	if story.phase == Story.Phase.HAND_DECISION:
		if absf(player.position.x - 3460.0) < 80.0:
			_resolve_hand(Story.HandChoice.SPARE)
		elif absf(player.position.x - 3260.0) < 82.0:
			_show_dialogue("Aluda", "I can turn from this custom and cover his body. Or I can hold H by the fallen man and take the hand.")
		return
	if story.phase == Story.Phase.COMPLETE:
		if absf(player.position.x - 3750.0) < 92.0:
			_enter_act_two()
		return
	if story.phase in [Story.Phase.MUTSAL_RIFLE, Story.Phase.MUTSAL_COVER, Story.Phase.MUTSAL_FINAL]:
		return
	var point := _nearby_point()
	if point.is_empty():
		return
	var id := String(point.id)
	if id == "report":
		story.receive_raid_report()
	elif story.phase == Story.Phase.RAID_REPORT:
		_show_dialogue("The trail", "Speak to the messenger at the sheepfold first.")
		return
	elif id in ["halter", "dogs", "gate"]:
		if id == "dogs":
			story.inspect_trail(&"dogs")
		var observation: Dictionary = fold_investigation.examine(StringName(id))
		if bool(observation.get("soothed", false)):
			var dog := get_node_or_null("Subareas/ShepherdsFold/SilentSheepdog") as SilentSheepdog
			if dog != null:
				dog.soothe()
		_show_dialogue(str(observation.get("speaker", "The trail")), str(observation.get("text", "")))
		queue_redraw()
		return
	elif id in ["hoofprints", "scrape", "grass"]:
		if id != "scrape":
			story.inspect_trail(StringName(id))
		var reading: Dictionary = wind_tracking.examine_clue(StringName(id))
		_show_dialogue(str(reading.get("speaker", "The trail")), str(reading.get("text", "")))
		queue_redraw()
		return
	elif id in ["ridge", "gully"]:
		var reading: Dictionary = wind_tracking.examine_route(StringName(id))
		_show_dialogue(str(reading.get("speaker", "The trail")), str(reading.get("text", "")))
		queue_redraw()
		return
	elif id == "river":
		story.visit_river()
		story.meet_sanata()
	elif id == "crags":
		if story.reach_crags():
			brother.visible = true
			rifle.enemy_timer = rifle.ENEMY_FIRE_INTERVAL + wind_tracking.approach_bonus_seconds()
			rifle.start()
			queue_redraw()
			return
	else:
		story.inspect_trail(StringName(id))
	_show_dialogue("Messenger" if id == "report" else "Sanata" if id == "river" else "The trail", str(point.text))


func _on_brother_defeated() -> void:
	if story.defeat_brother():
		brother.visible = false
		mutsal.visible = true
		mutsal_duel.begin(story)


func _on_mutsal_final() -> void:
	if story.phase != Story.Phase.HAND_DECISION:
		return
	mutsal.rotation = -1.35
	mutsal.position.y = 444
	_show_dialogue("Aluda", "He fought bravely. I must choose with my own hands, not let the old rule choose for me.")


func _resolve_hand(choice: int) -> void:
	if not story.decide_hand(choice):
		return
	if not story.finish_aftermath():
		return
	_hand_hold = 0.0
	if choice == Story.HandChoice.SPARE:
		_show_dialogue("Aluda", "I leave his hand untouched. I cover the fallen man and turn toward home.")
	else:
		_show_dialogue("Aluda", "I followed the old custom. Even now, with his rifle silent, the act feels heavy.")
	queue_redraw()


func can_leave_for_act_two() -> bool:
	return story.phase == Story.Phase.COMPLETE and story.hand_choice != Story.HandChoice.UNDECIDED


func _enter_act_two() -> void:
	if not can_leave_for_act_two() or _leaving_act_one:
		return
	_leaving_act_one = true
	get_tree().set_meta("aluda_act_one_hand_choice", int(story.hand_choice))
	# Fade after a confirmed, player-selected Act I outcome; not a teleport.
	var transition := CanvasLayer.new()
	transition.layer = 60
	transition.name = "ChapterTransition"
	add_child(transition)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.04, 0.08, 0.10, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	transition.add_child(veil)
	var fade := create_tween()
	fade.tween_property(veil, "color:a", 1.0, 0.6)
	fade.tween_callback(func() -> void:
		get_tree().change_scene_to_packed(ACT_TWO_CAMP)
	)


func _nearby_point() -> Dictionary:
	# Use the nearest sign so closely placed evidence does not mask another clue.
	var best: Dictionary = {}
	var closest: float = 75.0
	if absf(player.position.y - 440.0) >= 100.0:
		return best
	for point: Dictionary in _points:
		var distance: float = absf(player.position.x - float(point.x))
		if distance < closest:
			closest = distance
			best = point
	return best


func _draw() -> void:
	# Small, readable clues over the painted terrain. These are not new triggers.
	if story.phase != Story.Phase.TRACKING:
		return
	for point: Dictionary in _points:
		var clue_id: StringName = StringName(point.id)
		if clue_id not in [&"halter", &"dogs", &"gate", &"hoofprints", &"scrape", &"grass", &"ridge", &"gully", &"stones", &"birds"]:
			continue
		var x: float = float(point.x)
		var center := Vector2(x, 412.0)
		var examined: bool = false
		if clue_id in [&"halter", &"dogs", &"gate"]:
			examined = fold_investigation.inspected.has(clue_id)
		elif clue_id in [&"hoofprints", &"scrape", &"grass"]:
			examined = wind_tracking.clues.has(clue_id)
		elif clue_id == &"ridge":
			examined = wind_tracking.route_confirmed
		elif clue_id == &"gully":
			examined = wind_tracking.gully_inspected
		else:
			examined = story.trail_clues.has(clue_id)
		if examined:
			draw_circle(center, 3.2, Color("#8d9d89", 0.57))
		else:
			var pulse: float = 0.5 + 0.5 * sin(_marker_time * 2.2 + x * 0.02)
			draw_arc(center, 10.0 + 3.0 * pulse, 0.0, TAU, 24, Color("#efe0b1", 0.24 + pulse * 0.33), 1.6)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -6.0),
				center + Vector2(5.0, 0.0),
				center + Vector2(0.0, 6.0),
				center + Vector2(-5.0, 0.0),
			]), Color("#e8d4a0", 0.77))
