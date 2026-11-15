extends CanvasLayer
## Reusable dialogue, objective, and journal interface, created at runtime.

var _objective: Label
var _prompt: Label
var _dialogue_panel: PanelContainer
var _speaker: Label
var _body: Label
var _journal_panel: PanelContainer
var _journal_text: Label
var journal_visible: bool = false


func _ready() -> void:
	layer = 10
	var root: Control = Control.new()
	root.name = "StoryHUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_objective = _label(root, "", 20, Color("fff0d4"))
	_objective.position = Vector2(24, 20)
	_objective.size = Vector2(950, 40)

	_prompt = _label(root, "", 19, Color("fff2d9"))
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-240, -125)
	_prompt.size = Vector2(480, 40)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false

	_dialogue_panel = _panel(root, 0.12, 0.88, 0.69, 0.96)
	var dialogue_column: VBoxContainer = VBoxContainer.new()
	dialogue_column.add_theme_constant_override("separation", 12)
	_dialogue_panel.add_child(dialogue_column)
	_speaker = _label(dialogue_column, "", 23, Color("e4c897"))
	_body = _label(dialogue_column, "", 21, Color("f5e9d4"))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hint: Label = _label(dialogue_column, "E / Enter / Space: Continue     Esc: Close", 14, Color("b9a78d"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dialogue_panel.visible = false

	_journal_panel = _panel(root, 0.19, 0.81, 0.13, 0.83)
	var journal_column: VBoxContainer = VBoxContainer.new()
	journal_column.add_theme_constant_override("separation", 20)
	_journal_panel.add_child(journal_column)
	_label(journal_column, "XIZANE'S JOURNAL", 28, Color("e4c897"))
	_journal_text = _label(journal_column, "", 19, Color("f5e9d4"))
	_journal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label(journal_column, "J / Esc: Close journal", 14, Color("b9a78d"))
	_journal_panel.visible = false


func set_objective(value: String) -> void:
	_objective.text = "OBJECTIVE  •  " + value


func set_prompt(value: String) -> void:
	_prompt.text = value
	_prompt.visible = not value.is_empty() and not _dialogue_panel.visible and not journal_visible


func show_dialogue(speaker_name: String, line: String) -> void:
	_speaker.text = speaker_name
	_body.text = line
	_dialogue_panel.visible = true
	_prompt.visible = false


func hide_dialogue() -> void:
	_dialogue_panel.visible = false


func set_journal(quest_title: String, objective: String, entries: Array[String]) -> void:
	var output: String = quest_title + "\n\nCURRENT OBJECTIVE\n" + objective + "\n\nCLUES DISCOVERED\n"
	if entries.is_empty():
		output += "No clues yet. Talk to the Mtskheta Elder."
	else:
		for entry: String in entries:
			output += "• " + entry + "\n\n"
	_journal_text.text = output


func toggle_journal() -> void:
	journal_visible = not journal_visible
	_journal_panel.visible = journal_visible
	if journal_visible:
		_prompt.visible = false


func _label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _panel(parent: Node, left: float, right: float, top: float, bottom: float) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = left
	panel.anchor_right = right
	panel.anchor_top = top
	panel.anchor_bottom = bottom
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("211e1b", 0.96)
	style.border_color = Color("b7a17d")
	style.set_border_width_all(2)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel
