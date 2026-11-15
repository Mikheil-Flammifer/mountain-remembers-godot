extends Node2D
## Mtskheta story adapter: NPC proximity, reusable dialogue, HUD, and journal.
## E / Enter interacts; E / Enter / Space advances dialogue.
## J toggles the journal; Esc closes dialogue or journal without awarding clues.

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


func _ready() -> void:
	_player = get_parent().get_node_or_null("Xizane") as CharacterBody2D
	if _player == null:
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
	queue_redraw()


func _process(_delta: float) -> void:
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
		_update_prompt()
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return

	var interact: bool = (
		key.keycode == KEY_E
		or key.physical_keycode == KEY_E
		or key.keycode == KEY_ENTER
		or key.keycode == KEY_KP_ENTER
	)
	var journal_key: bool = key.keycode == KEY_J or key.physical_keycode == KEY_J
	var escape_key: bool = key.keycode == KEY_ESCAPE

	if _dialogue_active:
		if interact or key.keycode == KEY_SPACE:
			_advance_dialogue()
			get_viewport().set_input_as_handled()
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
		_start_interaction(_nearby_id)
		get_viewport().set_input_as_handled()


func _start_interaction(person_id: String) -> void:
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
	_hud.show_dialogue(
		str(_conversation.get("speaker", "")),
		str(lines[_line_index])
	)


func _advance_dialogue() -> void:
	_line_index += 1
	var lines: Array = _conversation.get("lines", [])
	if _line_index >= lines.size():
		_end_dialogue(true)
	else:
		_show_line()


func _end_dialogue(finished: bool) -> void:
	# A skipped conversation must not advance the journal.
	if finished and _conversation.has("complete_stage"):
		_journal.complete_step(
			int(_conversation["complete_stage"]),
			str(_conversation.get("journal", ""))
		)

	_dialogue_active = false
	_conversation.clear()
	_hud.hide_dialogue()
	if is_instance_valid(_player):
		_player.set_physics_process(true)
	_update_prompt()


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
			draw_arc(
			Vector2(px, FLOOR_Y - 77.0), 24.0,
			0.0, TAU, 32, Color("ead19e"), 2.0
			)
