extends Node2D
## Act 1 tracking section. Story state is owned by this encounter.

const Story = preload("res://scripts/systems/story/act_one_state.gd")
const ALUDA = preload("res://scenes/actors/player/aluda.tscn")
const MESSENGER = preload("res://scenes/visuals/actors/characters/messenger/messenger_visual.tscn")
const RIFLE = preload("res://scripts/levels/aluda/rifle_encounter.gd")
const BROTHER = preload("res://scenes/visuals/actors/characters/mutsal_brother/mutsal_brother_visual.tscn")
const SANATA = preload("res://scenes/visuals/actors/characters/sanata/sanata_visual.tscn")
const DIALOGUE_PANEL = preload("res://scripts/ui/aluda_dialogue_panel.gd")

var story = Story.new()
var player: CharacterBody2D
var dialogue_panel: AludaDialoguePanel
var prompt: Label
var trail_status: Label
var _marker_time: float = 0.0
var _marker_clock: float = 0.0
var rifle: RifleEncounter
var brother: Node2D
var _points := [
	{"id": "report", "x": 160.0, "label": "Messenger", "text": "The shepherds were attacked. Raiders took horses, including yours. Follow their trail toward Arkhoti."},
	{"id": "dogs", "x": 430.0, "label": "Sheepfold", "text": "The dogs are silent now. The attack passed before dawn."},
	{"id": "hoofprints", "x": 750.0, "label": "Hoofprints", "text": "Fresh hoofprints climb away from the sheepfold toward the high pasture."},
	{"id": "grass", "x": 1060.0, "label": "Bent grass", "text": "Bent grass and disturbed earth mark a hurried passage."},
	{"id": "river", "x": 1400.0, "label": "River detour", "text": "The river stones are wet with fresh prints. The raiders may reach cover while you take this longer path."},
	{"id": "stones", "x": 1720.0, "label": "Wet stones", "text": "Water on the stones shows where the horses crossed."},
	{"id": "birds", "x": 2050.0, "label": "Birdcalls", "text": "Birdcalls echo over the pasture as the dawn light reaches the crags."},
	{"id": "crags", "x": 2400.0, "label": "The crags", "text": "The trail leads among the rocks. The rifle encounter is the next part to be built."},
]


func _ready() -> void:
	_build_world()
	_build_hud()


func _build_world() -> void:
	var ground := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3500, 120)
	collision.shape = shape
	ground.position = Vector2(1650, 500)
	ground.add_child(collision)
	add_child(ground)
	player = ALUDA.instantiate()
	player.position = Vector2(50, 440)
	add_child(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -110)
	camera.zoom = Vector2(1.6, 1.6)
	camera.position_smoothing_enabled = true
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
	rifle = RIFLE.new()
	add_child(rifle)
	rifle.updated.connect(func(text: String): _show_dialogue("The crags", text))
	rifle.defeated.connect(_on_brother_defeated)
	queue_redraw()


func _build_hud() -> void:
	# Dialogue is a separate presentation component, anchored at the bottom.
	dialogue_panel = DIALOGUE_PANEL.new()
	dialogue_panel.name = "DialoguePanel"
	add_child(dialogue_panel)

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


func _process(delta: float) -> void:
	_marker_time += delta
	_marker_clock += delta
	if _marker_clock >= 0.12:
		_marker_clock = 0.0
		queue_redraw()
	if rifle.active:
		rifle.tick(delta, player.position.x >= 2500.0 and player.position.x <= 2580.0)
	var point := _nearby_point()
	if rifle.active:
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
		trail_status.text = "TRAIL SIGNS  %d / 5  (optional)" % story.trail_clues.size()
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
			rifle.fire(player.position.x > 2580.0 and player.position.x < 2820.0 and player.facing > 0.0)
			return
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			if story.phase == Story.Phase.BROTHER_FIGHT and not rifle.active:
				player.position = Vector2(2510, 440)
				rifle.player_health = 2
				rifle.enemy_health = 1
				rifle.loaded = true
				rifle.reload_step = 0
				rifle.enemy_timer = rifle.ENEMY_FIRE_INTERVAL
				rifle.start()
			else:
				rifle.reload_next()
			return
	if not event.is_action_pressed("talk") or event.is_echo():
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
	elif id == "river":
		story.visit_river()
		story.meet_sanata()
	elif id == "crags":
		if story.reach_crags():
			brother.visible = true
			rifle.start()
			queue_redraw()
			return
	else:
		story.inspect_trail(StringName(id))
	_show_dialogue("Messenger" if id == "report" else "Sanata" if id == "river" else "The trail", str(point.text))


func _on_brother_defeated() -> void:
	story.defeat_brother()
	brother.visible = false


func _nearby_point() -> Dictionary:
	for point: Dictionary in _points:
		if absf(player.position.x - float(point.x)) < 75.0 and absf(player.position.y - 440.0) < 100.0:
			return point
	return {}


func _draw() -> void:
	# Small, readable clues over the painted terrain. These are not new triggers.
	if story.phase != Story.Phase.TRACKING:
		return
	for point: Dictionary in _points:
		var clue_id: StringName = StringName(point.id)
		if clue_id not in [&"dogs", &"hoofprints", &"grass", &"stones", &"birds"]:
			continue
		var x: float = float(point.x)
		var center := Vector2(x, 412.0)
		if story.trail_clues.has(clue_id):
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
