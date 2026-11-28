class_name ActOneAreaBanner
extends CanvasLayer
## A discreet, temporary zone-entry title, separate from dialogue and quests.

var current_title: String = ""
var current_subtitle: String = ""
var visit_count: int = 0

var _card: PanelContainer
var _title: Label
var _subtitle: Label
var _tween: Tween


func _ready() -> void:
	layer = 12
	var overlay := Control.new()
	overlay.name = "AreaTitleOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_card = PanelContainer.new()
	_card.name = "AreaTitleCard"
	_card.anchor_left = 0.30
	_card.anchor_right = 0.70
	_card.anchor_top = 0.115
	_card.anchor_bottom = 0.235
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#18282c", 0.80)
	frame.border_color = Color("#b4a080", 0.54)
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(5)
	frame.set_content_margin_all(10)
	_card.add_theme_stylebox_override("panel", frame)
	overlay.add_child(_card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_card.add_child(column)
	_title = _new_label(19, Color("#edd7ad"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	var line := HSeparator.new()
	line.modulate = Color("#b6a37f", 0.35)
	column.add_child(line)
	_subtitle = _new_label(12, Color("#b5c2b5"))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_subtitle)

	_card.visible = false


func _new_label(font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	return label


func announce(title: String, subtitle: String) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	current_title = title
	current_subtitle = subtitle
	visit_count += 1
	_title.text = title
	_subtitle.text = subtitle
	_card.modulate.a = 0.0
	_card.visible = true
	_tween = create_tween()
	_tween.tween_property(_card, "modulate:a", 1.0, 0.35)
	_tween.tween_interval(2.4)
	_tween.tween_property(_card, "modulate:a", 0.0, 0.6)
	_tween.tween_callback(_hide)


func _hide() -> void:
	_card.visible = false
