extends Node2D
<<<<<<< HEAD
## Mtskheta opening story. Additive to the existing level and player systems.
## E / Enter interacts; E / Enter / Space advances dialogue; Esc dismisses it.

const INTERACT_DISTANCE: float = 115.0
const FLOOR_Y: float = 610.0

const PEOPLE: Array[Dictionary] = [
	{"id": "elder", "name": "Mtskheta Elder", "x": 680.0, "color": Color("655044")},
	{"id": "pilgrim", "name": "Pilgrim", "x": 1570.0, "color": Color("526b63")},
	{"id": "traveler", "name": "Highland Traveler", "x": 3050.0, "color": Color("514859")},
]

var _player: CharacterBody2D
var _nearby_id: String = ""
var _dialogue_active: bool = false
var _dialogue_lines: Array[String] = []
var _dialogue_index: int = 0
var _stage: int = 0
var _journal: Array[String] = []

var _hud: CanvasLayer
var _objective_label: Label
var _prompt_label: Label
var _dialogue_box: PanelContainer
var _speaker_label: Label
var _dialogue_label: Label
var _hint_label: Label
=======
## Mtskheta adapter: world-NPC proximity + reusable dialogue, HUD, quest state.
## Requires existing level scene Story node and sibling Xizane instance.

const DIALOGUES = preload("res://scripts/data/mtskheta_dialogues.gd")
const JOURNAL_SCRIPT = preload("res://scripts/systems/quest_journal.gd")
const HUD_SCRIPT = preload("res://scripts/ui/story_hud.gd")
const INTERACT_DISTANCE: float = 115.0
const FLOOR_Y: float = 610.0

var _player: CharacterBody2D
var _journal: Node
var _hud: CanvasLayer
var _nearby_id: String = ""
var _conversation: Dictionary = {}
var _line_index: int = 0
var _dialogue_active: bool = false
>>>>>>> bdb511f (feat(story): implement reusable dialogue and persistent quest journal)


func _ready() -> void:
	_player = get_parent().get_node_or_null("Xizane") as CharacterBody2D
	if _player == null:
<<<<<<< HEAD
		push_error("[MtskhetaStory] Xizane not found at ../Xizane")
		set_process(false)
		return
	_create_hud()
	_update_objective()
=======
		push_error("[MtskhetaStory] Expected Xizane at ../Xizane")
		set_process(false)
		set_process_unhandled_input(false)
		return

	_journal = Node.new()
	_journal.name = "QuestJournal"
	_journal.set_script(JOURNAL_SCRIPT)
	add_child(_journal)

	_hud = CanvasLayer.new()
	_hud.name = "StoryHUD"
	_hud.set_script(HUD_SCRIPT)
	add_child(_hud)

	_journal.changed.connect(_update_hud)
	_update_hud()
>>>>>>> bdb511f (feat(story): implement reusable dialogue and persistent quest journal)
	queue_redraw()


func _process(_delta: float) -> void:
<<<<<<< HEAD
	if _dialogue_active:
		return
	var nearest_id: String = ""
	var closest: float = INTERACT_DISTANCE
	for person: Dictionary in PEOPLE:
		var distance: float = absf(_player.global_position.x - float(person["x"]))
		if distance < closest:
			closest = distance
			nearest_id = str(person["id"])
	if _nearby_id != nearest_id:
		_nearby_id = nearest_id
=======
	if _dialogue_active or _hud.journal_visible:
		return
	var next_nearby: String = ""
	var nearest_distance: float = INTERACT_DISTANCE
	for person: Dictionary in DIALOGUES.PEOPLE:
		var distance: float = absf(_player.global_position.x - float(person["x"]))
		if distance < nearest_distance:
			nearest_distance = distance
			next_nearby = str(person["id"])
	if next_nearby != _nearby_id:
		_nearby_id = next_nearby
>>>>>>> bdb511f (feat(story): implement reusable dialogue and persistent quest journal)
		_update_prompt()
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
<<<<<<< HEAD
	var interact: bool = key.keycode == KEY_E or key.keycode == KEY_ENTER or key.physical_keycode == KEY_E
=======

	var interact: bool = (key.keycode == KEY_E or key.physical_keycode == KEY_E or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER)
	var journal_key: bool = key.keycode == KEY_J or key.physical_keycode == KEY_J
	var escape_key: bool = key.keycode == KEY_ESCAPE

>>>>>>> bdb511f (feat(story): implement reusable dialogue and persistent quest journal)
	if _dialogue_active:
		if interact or key.keycode == KEY_SPACE:
			_advance_dialogue()
			get_viewport().set_input_as_handled()
<<<<<<< HEAD
		elif key.keycode == KEY_ESCAPE:
			_end_dialogue()
			get_viewport().set_input_as_handled()
	elif interact and _nearby_id != "":
=======
		elif escape_key:
			_end_dialogue(false)
			get_viewport().set_input_as_handled()
		return

	if _hud.journal_visible:
		if journal_key or escape_key:
			_hud.toggle_journal()
			_player.set_physics_process(true)
			_update_prompt()
			get_viewport().set_input_as_handled()
		return

	if journal_key:
		_hud.toggle_journal()
		_player.velocity = Vector2.ZERO
		_player.set_physics_process(false)
		get_viewport().set_input_as_handled()
	elif interact and not _nearby_id.is_empty():
>>>>>>> bdb511f (feat(story): implement reusable dialogue and persistent quest journal)
		_start_interaction(_nearby_id)
		get_viewport().set_input_as_handled()


func _start_interaction(person_id: String) -> void:
<<<<<<< HEAD
	_dialogue_lines.clear()
	var speaker: String = ""
	match person_id:
		"elder":
			speaker = "Mtskheta Elder"
			if _stage == 0:
				_dialogue_lines = [
					"Xizane, you have been quiet since the news from Sakhare.",
					"Your sister Samdzivari vanished after the quarrel between the two villages.",
					"A pilgrim passing through Mtskheta spoke of the northern roads. Find them near the eastward path."
				]
				_set_stage(1, "The elder says a pilgrim may know the northern roads.")
			else:
				_dialogue_lines = ["You cannot untangle every rumor here. Seek the truth, Xizane."]
		"pilgrim":
			speaker = "Pilgrim"
			if _stage < 1:
				_dialogue_lines = ["The elder might help you understand where to begin."]
			elif _stage == 1:
				_dialogue_lines = [
					"The road north divides beyond the settled valleys.",
					"I met a traveler who had come down from Khevsureti. You will find them farther east.",
					"Listen carefully. In the mountains, a name can be remembered long after a person is gone."
				]
				_set_stage(2, "A highland traveler may have news from Khevsureti.")
			else:
				_dialogue_lines = ["You will find the traveler farther along the road."]
		"traveler":
			speaker = "Highland Traveler"
			if _stage < 2:
				_dialogue_lines = ["I have come a long way. Speak with those of Mtskheta first."]
			elif _stage == 2:
				_dialogue_lines = [
					"In the high villages I heard talk of a woman walking alone toward the mountains.",
					"No one could tell me her name. But some said she refused to return to the valley.",
					"If you seek her, the road through the Aragvi valley is your beginning."
				]
				_set_stage(3, "A woman may have been seen heading into the highlands.")
			else:
				_dialogue_lines = ["Follow the Aragvi valley. Travel carefully."]
	if _dialogue_lines.is_empty():
		return
	_dialogue_index = 0
	_dialogue_active = true
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)
	_speaker_label.text = speaker
	_dialogue_box.visible = true
	_prompt_label.visible = false
	_show_dialogue_line()


func _advance_dialogue() -> void:
	_dialogue_index += 1
	if _dialogue_index >= _dialogue_lines.size():
		_end_dialogue()
	else:
		_show_dialogue_line()


func _show_dialogue_line() -> void:
	_dialogue_label.text = _dialogue_lines[_dialogue_index]
	_hint_label.text = "E / Enter / Space — Continue    Esc — Close"


func _end_dialogue() -> void:
	_dialogue_active = false
	_dialogue_box.visible = false
=======
	_conversation = DIALOGUES.conversation(person_id, _journal.stage)
	var lines: Array = _conversation.get("lines", [])
	if lines.is_empty():
		return
	_dialogue_active = true
	_line_index = 0
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)
	_show_line()


func _show_line() -> void:
	var lines: Array = _conversation.get("lines", [])
	_hud.show_dialogue(str(_conversation.get("speaker", "")), str(lines[_line_index]))


func _advance_dialogue() -> void:
	_line_index += 1
	var lines: Array = _conversation.get("lines", [])
	if _line_index >= lines.size():
		_end_dialogue(true)
	else:
		_show_line()


func _end_dialogue(finished: bool) -> void:
	# Closing with Esc does not grant clues or advance the quest.
	if finished and _conversation.has("complete_stage"):
		_journal.complete_step(int(_conversation["complete_stage"]), str(_conversation.get("journal", "")))
	_dialogue_active = false
	_conversation.clear()
	_hud.hide_dialogue()
>>>>>>> bdb511f (feat(story): implement reusable dialogue and persistent quest journal)
	if is_instance_valid(_player):
		_player.set_physics_process(true)
	_update_prompt()


<<<<<<< HEAD
func _set_stage(stage: int, journal_entry: String) -> void:
	_stage = stage
	_journal.append(journal_entry)
	_update_objective()
	print("[MtskhetaStory] ", journal_entry)


func _update_objective() -> void:
	if _objective_label == null:
		return
	match _stage:
		0: _objective_label.text = "OBJECTIVE  •  Speak with the Mtskheta elder"
		1: _objective_label.text = "OBJECTIVE  •  Find the pilgrim along the road"
		2: _objective_label.text = "OBJECTIVE  •  Speak with the highland traveler"
		_: _objective_label.text = "OBJECTIVE  •  Journey toward the Aragvi valley (next chapter)"


func _update_prompt() -> void:
	if _prompt_label == null:
		return
	_prompt_label.visible = _nearby_id != "" and not _dialogue_active
	match _nearby_id:
		"elder": _prompt_label.text = "E / Enter  •  Speak with Mtskheta Elder"
		"pilgrim": _prompt_label.text = "E / Enter  •  Speak with Pilgrim"
		"traveler": _prompt_label.text = "E / Enter  •  Speak with Highland Traveler"
		_: _prompt_label.text = ""


func _create_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.name = "StoryHUD"
	_hud.layer = 10
	add_child(_hud)
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(root)

	_objective_label = Label.new()
	_objective_label.position = Vector2(24, 20)
	_objective_label.add_theme_font_size_override("font_size", 20)
	_objective_label.add_theme_color_override("font_color", Color("fff0d4"))
	root.add_child(_objective_label)

	_prompt_label = Label.new()
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position = Vector2(-225, -140)
	_prompt_label.custom_minimum_size = Vector2(450, 42)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 19)
	_prompt_label.add_theme_color_override("font_color", Color("fff2d9"))
	_prompt_label.visible = false
	root.add_child(_prompt_label)

	_dialogue_box = PanelContainer.new()
	_dialogue_box.anchor_left = 0.12
	_dialogue_box.anchor_right = 0.88
	_dialogue_box.anchor_top = 0.69
	_dialogue_box.anchor_bottom = 0.96
	_dialogue_box.visible = false
	_dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("211e1b", 0.95)
	style.border_color = Color("b7a17d")
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	_dialogue_box.add_theme_stylebox_override("panel", style)
	root.add_child(_dialogue_box)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_dialogue_box.add_child(column)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 23)
	_speaker_label.add_theme_color_override("font_color", Color("e4c897"))
	column.add_child(_speaker_label)
	_dialogue_label = Label.new()
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_label.add_theme_font_size_override("font_size", 21)
	_dialogue_label.add_theme_color_override("font_color", Color("f5e9d4"))
	column.add_child(_dialogue_label)
	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.add_theme_color_override("font_color", Color("b9a78d"))
	column.add_child(_hint_label)


func _draw() -> void:
	for person: Dictionary in PEOPLE:
		var px: float = float(person["x"])
		var main_color: Color = person["color"]
		# Small, legible silhouette placeholder. Replace with character sprites later.
		draw_circle(Vector2(px, FLOOR_Y - 73.0), 15.0, Color("d0b595"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(px - 18, FLOOR_Y - 56),
			Vector2(px + 18, FLOOR_Y - 56),
			Vector2(px + 25, FLOOR_Y),
			Vector2(px - 25, FLOOR_Y)
		]), main_color)
		if str(person["id"]) == _nearby_id:
			draw_arc(Vector2(px, FLOOR_Y - 77), 24.0, 0.0, TAU, 32, Color("ead19e"), 2.0)
=======
func _update_hud() -> void:
	_hud.set_objective(_journal.objective_text())
	_hud.set_journal("THE ROAD NORTH", _journal.objective_text(), _journal.entries)


func _update_prompt() -> void:
	if _nearby_id.is_empty():
		_hud.set_prompt("")
		return
	for person: Dictionary in DIALOGUES.PEOPLE:
		if str(person["id"]) == _nearby_id:
			_hud.set_prompt("E / Enter  •  Speak with " + str(person["name"]))
			return
	_hud.set_prompt("")


func _draw() -> void:
	for person: Dictionary in DIALOGUES.PEOPLE:
		var px: float = float(person["x"])
		var main_color: Color = person["color"]
		draw_circle(Vector2(px, FLOOR_Y - 73.0), 15.0, Color("d0b595"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(px - 18.0, FLOOR_Y - 56.0),
			Vector2(px + 18.0, FLOOR_Y - 56.0),
			Vector2(px + 25.0, FLOOR_Y),
			Vector2(px - 25.0, FLOOR_Y)
		]), main_color)
		if str(person["id"]) == _nearby_id:
			draw_arc(Vector2(px, FLOOR_Y - 77.0), 24.0, 0.0, TAU, 32, Color("ead19e"), 2.0)
>>>>>>> bdb511f (feat(story): implement reusable dialogue and persistent quest journal)
