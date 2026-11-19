extends Node

## Reusable Market/Streets NPC interaction and journal adapter.
## Existing cathedral and original Mtskheta dialogue remain untouched.

const INTERACTION_RADIUS: float = 115.0

var _player: CharacterBody2D
var _journal: MtskhetaInvestigationJournal
var _hud: MtskhetaInvestigationHUD
var _npcs: Array[MtskhetaInvestigationNPC] = []
var _nearby: MtskhetaInvestigationNPC
var _talking: bool = false
var _lines: Array = []
var _line_index: int = 0
var _pending_clue: String = ""
var _deduction_feedback: String = ""


func _ready() -> void:
    _player = get_parent().get_node_or_null("Player") as CharacterBody2D
    if _player == null:
        _player = get_parent().get_node_or_null("Xizane") as CharacterBody2D
    if _player == null:
        push_error("[Investigation] Scene has no Player/Xizane")
        set_process(false)
        set_process_unhandled_input(false)
        return

    for child: Node in get_parent().get_children():
        if child is MtskhetaInvestigationNPC:
            _npcs.append(child as MtskhetaInvestigationNPC)

    _journal = MtskhetaInvestigationJournal.new()
    _journal.name = "InvestigationJournal"
    add_child(_journal)

    _hud = MtskhetaInvestigationHUD.new()
    _hud.name = "InvestigationHUD"
    add_child(_hud)

    _journal.changed.connect(_refresh_hud)
    _refresh_hud()


func _process(_delta: float) -> void:
    if _talking or _hud.journal_visible:
        return

    var feet: Vector2 = _player.global_position + Vector2(0.0, 48.0)
    var closest: MtskhetaInvestigationNPC = null
    var best_distance: float = INTERACTION_RADIUS

    for npc: MtskhetaInvestigationNPC in _npcs:
        if not is_instance_valid(npc):
            continue
        var distance: float = feet.distance_to(npc.global_position)
        if distance < best_distance:
            closest = npc
            best_distance = distance

    if closest != _nearby:
        if is_instance_valid(_nearby):
            _nearby.set_highlighted(false)
        _nearby = closest
        if is_instance_valid(_nearby):
            _nearby.set_highlighted(true)
        _refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key: InputEventKey = event as InputEventKey
    if not key.pressed or key.echo:
        return

    var interact: bool = (
        event.is_action_pressed("talk")
        or key.keycode == KEY_E
        or key.physical_keycode == KEY_E
        or key.keycode == KEY_ENTER
        or key.keycode == KEY_KP_ENTER
    )
    var advance: bool = (
        interact
        or key.keycode == KEY_SPACE
        or key.physical_keycode == KEY_SPACE
    )
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
            _deduction_feedback = ""
            _resume_player()
            _refresh_prompt()
            get_viewport().set_input_as_handled()
        elif _can_deduce():
            var choice: int = _number_choice(key)
            if choice != 0:
                _submit_deduction(choice)
                get_viewport().set_input_as_handled()
        return

    if journal_key:
        _hud.toggle_journal()
        _freeze_player()
        get_viewport().set_input_as_handled()
    elif interact and is_instance_valid(_nearby):
        _start_dialogue(_nearby.npc_id)
        get_viewport().set_input_as_handled()


func _start_dialogue(npc_id: String) -> void:
    var conversation: Dictionary = MtskhetaInvestigationData.conversation(
        npc_id,
        _journal.has_clue(MtskhetaInvestigationData.MARKET_CLUE),
        _journal.has_clue(MtskhetaInvestigationData.STREETS_CLUE)
    )
    var dialogue_lines: Array = conversation.get("lines", [])
    if dialogue_lines.is_empty():
        return

    _lines = dialogue_lines
    _pending_clue = str(conversation.get("clue", ""))
    _line_index = 0
    _talking = true
    _freeze_player()
    _hud.set_prompt("")
    _show_line()


func _show_line() -> void:
    var line: Dictionary = _lines[_line_index]
    _hud.show_dialogue(str(line.get("speaker", "")), str(line.get("text", "")))


func _advance_dialogue() -> void:
    _line_index += 1
    if _line_index < _lines.size():
        _show_line()
    else:
        _finish_dialogue(true)


func _finish_dialogue(completed: bool) -> void:
    _talking = false
    _hud.hide_dialogue()
    if completed and not _pending_clue.is_empty():
        _journal.record_clue(_pending_clue)
    _pending_clue = ""
    _lines.clear()
    _resume_player()
    _refresh_hud()
    _refresh_prompt()


func _freeze_player() -> void:
    _player.velocity = Vector2.ZERO
    _player.set_physics_process(false)


func _resume_player() -> void:
    var health: Node = _player.get_node_or_null("HealthComponent")
    if health != null and bool(health.get("is_dead")):
        return
    _player.set_physics_process(true)


func _refresh_hud() -> void:
    var market_known: bool = _journal.has_clue(MtskhetaInvestigationData.MARKET_CLUE)
    var streets_known: bool = _journal.has_clue(MtskhetaInvestigationData.STREETS_CLUE)
    var objective: String = "Speak with the Aragvi Merchant in the Market"
    if market_known:
        objective = "Find the Pilgrim in the old Streets"
    if streets_known:
        objective = "Open the journal (J) to compare the two accounts"
    if _journal.has_clue(MtskhetaInvestigationData.DEDUCTION_CLUE):
        objective = "Seek further evidence at Svetitskhoveli"

    _hud.set_objective(objective)
    var journal_entries: Array[String] = []
    for entry: String in _journal.entries:
        journal_entries.append(entry)
    _hud.set_journal("THE ROAD NORTH", objective, journal_entries)
    if _can_deduce():
        _hud.add_journal_note(
            "COMPARE THE WITNESSES\n"
            + "1 — Both witnesses proved the woman is Samdzivari.\n"
            + "2 — The northern road is a lead, but identity is uncertain.\n"
            + "3 — The witnesses must describe the same traveler.\n\n"
            + "Press 1, 2, or 3.\n" + _deduction_feedback
        )


func _refresh_prompt() -> void:
    if _talking or _hud.journal_visible or not is_instance_valid(_nearby):
        _hud.set_prompt("")
        return
    _hud.set_prompt("E / Enter  -  Speak with " + _nearby.display_name)


func _can_deduce() -> bool:
    return (
        MtskhetaInvestigationData.deduction_available(_journal.entries)
        and not _journal.has_clue(MtskhetaInvestigationData.DEDUCTION_CLUE)
    )


func _number_choice(key: InputEventKey) -> int:
    var code: Key = key.physical_keycode
    if code == 0:
        code = key.keycode
    match code:
        KEY_1, KEY_KP_1:
            return 1
        KEY_2, KEY_KP_2:
            return 2
        KEY_3, KEY_KP_3:
            return 3
    return 0


func _submit_deduction(choice: int) -> void:
    _deduction_feedback = MtskhetaInvestigationData.deduction_feedback(choice)
    if choice == 2:
        _journal.record_clue(MtskhetaInvestigationData.DEDUCTION_CLUE)
    _refresh_hud()
