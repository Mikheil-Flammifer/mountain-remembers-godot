extends Node

## Cathedral dialogue + rest point using the existing StoryHUD and
## QuestJournal saved state. The monk records a clue without skipping
## the Mtskheta Elder -> Pilgrim -> Highland Traveler quest stages.

const INTERACTION_RADIUS: float = 112.0
const QUEST_ENTRY: String = (
	"At Svetitskhoveli, a monk urged me to follow the Aragvi "
	+ "toward the northern mountain road. I must find Samdzivari."
)

@onready var _player: CharacterBody2D = get_parent().get_node("Player") as CharacterBody2D
@onready var _monk: Node2D = get_parent().get_node("CourtyardMonk") as Node2D
@onready var _rest_point: Node2D = get_parent().get_node("RestPoint") as Node2D
@onready var _journal: Node = get_parent().get_node("QuestJournal")
@onready var _hud: CathedralStoryHUD = get_parent().get_node("CathedralStoryHUD") as CathedralStoryHUD

var _nearby: String = ""
var _talking: bool = false
var _lines: Array[Dictionary] = []
var _line_index: int = 0
var _record_monk_clue: bool = false


func _ready() -> void:
	_journal.connect("changed", Callable(self, "_refresh_journal"))
	call_deferred("_refresh_journal")


func _process(_delta: float) -> void:
	if _talking or _hud.journal_visible:
		return

	var feet: Vector2 = _player.global_position + Vector2(0.0, 48.0)
	var next_nearby: String = ""
	var best_distance: float = INTERACTION_RADIUS

	var monk_distance: float = feet.distance_to(_monk.global_position)
	if monk_distance < best_distance:
		next_nearby = "monk"
		best_distance = monk_distance

	var rest_distance: float = feet.distance_to(_rest_point.global_position)
	if rest_distance < best_distance:
		next_nearby = "rest"

	if next_nearby != _nearby:
		_nearby = next_nearby
		_refresh_prompt()


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
	var advance: bool = interact or key.keycode == KEY_SPACE
	var journal_key: bool = key.keycode == KEY_J or key.physical_keycode == KEY_J
	var escape_key: bool = key.keycode == KEY_ESCAPE

	if _talking:
		if advance:
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		elif escape_key:
			_finish_dialogue(false)
			get_viewport().set_input_as_handled()
		return

	if _hud.journal_visible:
		if journal_key or escape_key:
			_hud.toggle_journal()
			_resume_player()
			_refresh_prompt()
			get_viewport().set_input_as_handled()
		return

	if journal_key:
		_hud.toggle_journal()
		_freeze_player()
		get_viewport().set_input_as_handled()
	elif interact and _nearby == "monk":
		_start_monk_dialogue()
		get_viewport().set_input_as_handled()
	elif interact and _nearby == "rest":
		_rest_at_courtyard()
		get_viewport().set_input_as_handled()


func _start_monk_dialogue() -> void:
	_record_monk_clue = not _journal.call("has_clue", QUEST_ENTRY)

	if _record_monk_clue:
		_lines = [
			{"speaker": "Monk", "text": "You have been absent from prayer, Xizane."},
			{"speaker": "Xizane", "text": "I saw Samdzivari in a vision. Dali said my sister still lives."},
			{"speaker": "Monk", "text": "A vision may guide, but the road will ask courage of you."},
			{"speaker": "Xizane", "text": "Then I will follow the Aragvi toward the mountains."},
			{"speaker": "Monk", "text": "Go by the terraces to the northern road. Remember why you travel."},
		]
	else:
		_lines = [
			{"speaker": "Monk", "text": "May your search for Samdzivari lead you to the truth."},
			{"speaker": "Xizane", "text": "I will remember your words."},
		]

	_open_dialogue()


func _rest_at_courtyard() -> void:
	if _player.has_method("set_resting"):
		_player.call("set_resting", true)

	var health: Node = _player.get_node_or_null("HealthComponent")
	if health != null and health.has_method("restore_full_health"):
		health.call("restore_full_health")

	var manager: Node = get_node_or_null("/root/MtskhetaTransitionManager")
	if manager == null:
		push_warning("Rest point: MtskhetaTransitionManager Autoload missing")
	else:
		manager.call(
			"activate_checkpoint",
			get_tree().current_scene.scene_file_path,
			"cathedral_rest"
		)

	_record_monk_clue = false
	_lines = [
		{"speaker": "Svetitskhoveli", "text": "You rest in the quiet courtyard. Your health is restored. This is now your checkpoint."}
	]
	_open_dialogue()


func _open_dialogue() -> void:
	_talking = true
	_line_index = 0
	_freeze_player()
	_hud.set_prompt("")
	_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_line_index]
	_hud.show_dialogue(str(line["speaker"]), str(line["text"]))


func _advance_dialogue() -> void:
	_line_index += 1
	if _line_index < _lines.size():
		_show_line()
	else:
		_finish_dialogue(true)


func _finish_dialogue(completed: bool) -> void:
	if _player.has_method("set_resting"):
		_player.call("set_resting", false)

	if completed and _record_monk_clue:
		_journal.call("record_clue", QUEST_ENTRY)

	_record_monk_clue = false
	_lines.clear()
	_talking = false
	_hud.hide_dialogue()
	_resume_player()
	_refresh_journal()
	_refresh_prompt()


func _freeze_player() -> void:
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)


func _resume_player() -> void:
	var health: Node = _player.get_node_or_null("HealthComponent")
	if health != null and bool(health.get("is_dead")):
		return
	_player.set_physics_process(true)


func _refresh_journal() -> void:
	var heard_guidance: bool = bool(_journal.call("has_clue", QUEST_ENTRY))
	var objective: String = "Speak with the monk at Svetitskhoveli"
	if heard_guidance:
		objective = "Follow the terraces toward Mtskheta's northern road"

	_hud.set_objective(objective)

	var entries: Array[String] = []
	var raw_entries: Array = _journal.get("entries") as Array
	for item: Variant in raw_entries:
		entries.append(str(item))
	_hud.set_journal("THE ROAD NORTH", objective, entries)


func _refresh_prompt() -> void:
	if _talking or _hud.journal_visible:
		_hud.set_prompt("")
		return

	match _nearby:
		"monk":
			_hud.set_prompt("E / Enter  -  Speak with the monk")
		"rest":
			_hud.set_prompt("E / Enter  -  Rest at the courtyard")
		_:
			_hud.set_prompt("")
