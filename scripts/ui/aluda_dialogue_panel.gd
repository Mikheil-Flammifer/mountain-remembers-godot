class_name AludaDialoguePanel
extends CanvasLayer
## Reusable in-world story panel for Aluda's conversations and trail narration.
## Presentation only: gameplay decides when to show each line.

signal dismissed

@export var characters_per_second: float = 55.0

var is_open: bool = false
var current_speaker: String = ""
var current_text: String = ""

var _panel: PanelContainer
var _speaker: Label
var _chapter: Label
var _body: RichTextLabel
var _continue_hint: Label
var _reveal_progress: float = 0.0


func _ready() -> void:
	layer = 20
	var overlay := Control.new()
	overlay.name = "DialogueOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel = PanelContainer.new()
	_panel.name = "DialogueCard"
	_panel.anchor_left = 0.08
	_panel.anchor_right = 0.92
	_panel.anchor_top = 0.70
	_panel.anchor_bottom = 0.96
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#172124", 0.96)
	frame.border_color = Color("#a9926d", 0.87)
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(11)
	frame.set_content_margin_all(19)
	frame.shadow_color = Color("#091011", 0.40)
	frame.shadow_size = 10
	_panel.add_theme_stylebox_override("panel", frame)
	overlay.add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_panel.add_child(row)

	var accent := ColorRect.new()
	accent.name = "StoneInlay"
	accent.color = Color("#a9926d", 0.87)
	accent.custom_minimum_size = Vector2(3, 0)
	accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent)

	var column := VBoxContainer.new()
	column.name = "TextColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	row.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)

	_speaker = _make_label("", 20, Color("#e8c997"))
	_speaker.name = "Speaker"
	_speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_speaker)

	_chapter = _make_label("ACT I   /   THE HIGH PASTURE", 12, Color("#839a99"))
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_chapter)

	var divider := HSeparator.new()
	divider.modulate = Color("#b09c77", 0.36)
	column.add_child(divider)

	_body = RichTextLabel.new()
	_body.name = "DialogueText"
	_body.bbcode_enabled = false
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_theme_font_size_override("normal_font_size", 21)
	_body.add_theme_color_override("default_color", Color("#f4ebdd"))
	column.add_child(_body)

	_continue_hint = _make_label("ENTER  •  CLOSE    ESC  •  CLOSE", 13, Color("#c0b49a"))
	_continue_hint.name = "ContinueHint"
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_continue_hint)

	_panel.visible = false
	set_process(false)


func set_location(location_name: String) -> void:
	set_chapter_location("ACT I", location_name)


func set_chapter_location(chapter_name: String, location_name: String) -> void:
	if is_instance_valid(_chapter):
		_chapter.text = chapter_name.to_upper() + "   /   " + location_name.to_upper()


func _make_label(value: String, size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	return label


func show_line(speaker_name: String, line: String, instant: bool = false) -> void:
	current_speaker = speaker_name
	current_text = line
	_speaker.text = speaker_name.to_upper()
	_body.text = line
	_panel.visible = true
	is_open = true
	_reveal_progress = 0.0
	if instant or line.is_empty():
		reveal_all()
	else:
		_body.visible_characters = 0
		_continue_hint.text = "ENTER  •  REVEAL    ESC  •  CLOSE"
		set_process(true)


func _process(delta: float) -> void:
	if not is_open:
		return
	_reveal_progress += maxf(delta, 0.0) * characters_per_second
	var count: int = _body.get_total_character_count()
	_body.visible_characters = mini(count, int(_reveal_progress))
	if _body.visible_characters >= count:
		reveal_all()


func reveal_all() -> void:
	_body.visible_characters = -1
	_reveal_progress = float(_body.get_total_character_count())
	_continue_hint.text = "ENTER  •  CLOSE    ESC  •  CLOSE"
	set_process(false)


func advance() -> void:
	if not is_open:
		return
	if _body.visible_characters >= 0:
		reveal_all()
	else:
		close()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	set_process(false)
	dismissed.emit()
