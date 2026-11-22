extends Area2D
## Interactive wayside rest point.
## E sits/rests; E again stands.
## Up/Down select, Left/Right or Tab switch category, Enter/Space upgrades.
## Mouse input and legacy 1-5 shortcuts are supported too.

@export var spawn_id: String = "rest_1"

const PLAYER_UPGRADES: Array[String] = ["hp", "energy"]
const ITEM_UPGRADES: Array[String] = ["blade", "shield", "stone"]
const UPGRADE_NAMES: Dictionary = {
	"blade": "Mountain Blade",
	"shield": "Shield",
	"stone": "Healing Stone",
	"hp": "Vitality",
	"energy": "Endurance",
}
const UPGRADE_SUBTITLES: Dictionary = {
	"blade": "Increase blade damage",
	"shield": "Block for less energy",
	"stone": "Restore more HP per stone",
	"hp": "Increase maximum HP",
	"energy": "Increase maximum energy",
}
const UPGRADE_DESCRIPTIONS: Dictionary = {
	"blade": "Strengthen the Mountain Blade. Higher levels increase every sword strike, including combo and dash attacks.",
	"shield": "Reinforce Xizane's shield technique. Blocking costs less energy, guard breaks hurt less, and perfect guards become slightly easier.",
	"stone": "Refine the healing stone ritual. The number of stones stays limited, but every stone restores more health.",
	"hp": "Increase Xizane's vitality. More maximum HP gives additional room for mistakes against strong enemies and traps.",
	"energy": "Increase Xizane's endurance. More energy supports longer guard pressure, movement, jumps and repeated attacks.",
}

var _inside: bool = false
var _prompt: Label
var _lit: bool = false
var _elapsed: float = 0.0

var _menu_layer: CanvasLayer
var _menu_panel: PanelContainer
var _player_tab: Button
var _items_tab: Button
var _cards_column: VBoxContainer
var _detail_title: Label
var _detail_level: Label
var _detail_description: Label
var _detail_current: Label
var _detail_next: Label
var _detail_cost: Label
var _detail_hint: Label
var _score_label: Label
var _status_label: Label

var _card_buttons: Dictionary = {}
var _card_title_labels: Dictionary = {}
var _card_value_labels: Dictionary = {}
var _card_cost_labels: Dictionary = {}
var _card_progress: Dictionary = {}

var _active_category: String = "player"
var _selected_index: int = 0
var _active_player: Node = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1

	var sensor := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(170, 140)
	sensor.shape = rect
	sensor.position = Vector2(0, -68)
	add_child(sensor)

	_prompt = Label.new()
	_prompt.position = Vector2(-155, -177)
	_prompt.custom_minimum_size = Vector2(310, 34)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color("#f5dfaa"))
	_prompt.add_theme_color_override("font_outline_color", Color("#2d302b"))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.text = "E  -  Rest at the wayside cross"
	_prompt.visible = false
	add_child(_prompt)

	_build_upgrade_menu()
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)


func _build_upgrade_menu() -> void:
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 130
	add_child(_menu_layer)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.015, 0.018, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_layer.add_child(dim)

	_menu_panel = PanelContainer.new()
	_menu_panel.anchor_left = 0.08
	_menu_panel.anchor_top = 0.08
	_menu_panel.anchor_right = 0.92
	_menu_panel.anchor_bottom = 0.92
	_menu_panel.offset_left = 0.0
	_menu_panel.offset_top = 0.0
	_menu_panel.offset_right = 0.0
	_menu_panel.offset_bottom = 0.0
	_menu_panel.custom_minimum_size = Vector2(760, 500)
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_layer.add_child(_menu_panel)

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.025, 0.030, 0.032, 0.985)
	frame.border_color = Color("#796745")
	frame.set_border_width_all(2)
	frame.corner_radius_top_left = 12
	frame.corner_radius_top_right = 12
	frame.corner_radius_bottom_left = 12
	frame.corner_radius_bottom_right = 12
	frame.content_margin_left = 24
	frame.content_margin_right = 24
	frame.content_margin_top = 20
	frame.content_margin_bottom = 18
	_menu_panel.add_theme_stylebox_override("panel", frame)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	_menu_panel.add_child(outer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	outer.add_child(header)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)

	var title := Label.new()
	title.text = "WAYSIDE REST"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ead7a5"))
	title_stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Strengthen Xizane or improve the equipment he carries."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#a9a18e"))
	title_stack.add_child(subtitle)

	_score_label = Label.new()
	_score_label.text = "SCORE  0"
	_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 20)
	_score_label.add_theme_color_override("font_color", Color("#e1c279"))
	header.add_child(_score_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	outer.add_child(tabs)

	_player_tab = _make_tab_button("PLAYER UPGRADES")
	_player_tab.pressed.connect(Callable(self, "_on_player_tab_pressed"))
	tabs.add_child(_player_tab)

	_items_tab = _make_tab_button("ITEM UPGRADES")
	_items_tab.pressed.connect(Callable(self, "_on_items_tab_pressed"))
	tabs.add_child(_items_tab)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	outer.add_child(body)

	var list_frame := PanelContainer.new()
	list_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_frame.size_flags_stretch_ratio = 1.15
	list_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(list_frame)

	var list_style := StyleBoxFlat.new()
	list_style.bg_color = Color(0.045, 0.052, 0.052, 0.88)
	list_style.border_color = Color("#4b4233")
	list_style.set_border_width_all(1)
	list_style.corner_radius_top_left = 8
	list_style.corner_radius_top_right = 8
	list_style.corner_radius_bottom_left = 8
	list_style.corner_radius_bottom_right = 8
	list_style.content_margin_left = 12
	list_style.content_margin_right = 12
	list_style.content_margin_top = 12
	list_style.content_margin_bottom = 12
	list_frame.add_theme_stylebox_override("panel", list_style)

	_cards_column = VBoxContainer.new()
	_cards_column.add_theme_constant_override("separation", 9)
	list_frame.add_child(_cards_column)

	var detail_frame := PanelContainer.new()
	detail_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_frame.size_flags_stretch_ratio = 0.85
	detail_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(detail_frame)

	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.035, 0.041, 0.043, 0.94)
	detail_style.border_color = Color("#65583f")
	detail_style.set_border_width_all(1)
	detail_style.corner_radius_top_left = 8
	detail_style.corner_radius_top_right = 8
	detail_style.corner_radius_bottom_left = 8
	detail_style.corner_radius_bottom_right = 8
	detail_style.content_margin_left = 18
	detail_style.content_margin_right = 18
	detail_style.content_margin_top = 16
	detail_style.content_margin_bottom = 16
	detail_frame.add_theme_stylebox_override("panel", detail_style)

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 10)
	detail_frame.add_child(details)

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 24)
	_detail_title.add_theme_color_override("font_color", Color("#ead7a5"))
	details.add_child(_detail_title)

	_detail_level = Label.new()
	_detail_level.add_theme_font_size_override("font_size", 13)
	_detail_level.add_theme_color_override("font_color", Color("#c8b88e"))
	details.add_child(_detail_level)

	_detail_description = Label.new()
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_description.add_theme_font_size_override("font_size", 14)
	_detail_description.add_theme_color_override("font_color", Color("#c6c1b4"))
	details.add_child(_detail_description)

	_detail_current = Label.new()
	_detail_current.add_theme_font_size_override("font_size", 15)
	_detail_current.add_theme_color_override("font_color", Color("#d9d1bb"))
	details.add_child(_detail_current)

	_detail_next = Label.new()
	_detail_next.add_theme_font_size_override("font_size", 15)
	_detail_next.add_theme_color_override("font_color", Color("#9fca91"))
	details.add_child(_detail_next)

	_detail_cost = Label.new()
	_detail_cost.add_theme_font_size_override("font_size", 17)
	detail_cost_color(Color("#e1c279"))
	details.add_child(_detail_cost)

	_detail_hint = Label.new()
	_detail_hint.text = "ENTER / SPACE  Upgrade"
	_detail_hint.add_theme_font_size_override("font_size", 12)
	_detail_hint.add_theme_color_override("font_color", Color("#969181"))
	details.add_child(_detail_hint)

	_status_label = Label.new()
	_status_label.text = "↑ ↓ Select    ← → / TAB Category    ENTER Upgrade    E Stand"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color("#a9a18e"))
	outer.add_child(_status_label)

	_menu_layer.visible = false


func detail_cost_color(color: Color) -> void:
	_detail_cost.add_theme_color_override("font_color", color)


func _make_tab_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(220, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 14)
	return button


func _make_upgrade_card(kind: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(360, 104)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = ""
	button.pressed.connect(Callable(self, "_on_card_pressed").bind(kind))
	button.mouse_entered.connect(Callable(self, "_on_card_hovered").bind(kind))

	var content := VBoxContainer.new()
	button.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_top = 10
	content.offset_right = -14
	content.offset_bottom = -9
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)

	var top := HBoxContainer.new()
	content.add_child(top)

	var card_title := Label.new()
	card_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_title.add_theme_font_size_override("font_size", 17)
	card_title.add_theme_color_override("font_color", Color("#eadfc2"))
	top.add_child(card_title)

	var card_cost := Label.new()
	card_cost.add_theme_font_size_override("font_size", 13)
	card_cost.add_theme_color_override("font_color", Color("#d9bd75"))
	top.add_child(card_cost)

	var card_value := Label.new()
	card_value.add_theme_font_size_override("font_size", 12)
	card_value.add_theme_color_override("font_color", Color("#aaa797"))
	content.add_child(card_value)

	var progress := ProgressBar.new()
	progress.min_value = 1
	progress.max_value = 5
	progress.value = 1
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 9)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(progress)

	_card_buttons[kind] = button
	_card_title_labels[kind] = card_title
	_card_value_labels[kind] = card_value
	_card_cost_labels[kind] = card_cost
	_card_progress[kind] = progress
	return button


func _on_player_tab_pressed() -> void:
	_set_category("player")


func _on_items_tab_pressed() -> void:
	_set_category("items")


func _on_card_hovered(kind: String) -> void:
	_select_kind(kind)


func _on_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = true
		_prompt.visible = true
		_update_prompt(body)


func _on_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_inside = false
	_prompt.visible = false
	if body.has_method("is_resting") and bool(body.call("is_resting")):
		body.call("set_resting", false)
	_hide_upgrade_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not _inside or not event is InputEventKey:
		return

	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("set_resting"):
		return

	var currently_resting: bool = false
	if player.has_method("is_resting"):
		currently_resting = bool(player.call("is_resting"))

	if key.keycode == KEY_E or key.physical_keycode == KEY_E:
		if currently_resting:
			player.call("set_resting", false)
			_prompt.text = "E  -  Rest at the wayside cross"
			_hide_upgrade_menu()
		else:
			player.call("set_resting", true)
			_restore_player(player)
			_activate_checkpoint()
			_respawn_scene_enemies()
			_lit = true
			_prompt.text = "E  -  Stand up"
			_show_upgrade_menu(player)
		get_viewport().set_input_as_handled()
		queue_redraw()
		return

	if not currently_resting:
		return

	if key.keycode == KEY_TAB:
		_toggle_category()
		get_viewport().set_input_as_handled()
		return

	if key.keycode == KEY_LEFT or key.keycode == KEY_A:
		_set_category("player")
		get_viewport().set_input_as_handled()
		return

	if key.keycode == KEY_RIGHT or key.keycode == KEY_D:
		_set_category("items")
		get_viewport().set_input_as_handled()
		return

	if key.keycode == KEY_UP or key.keycode == KEY_W:
		_move_selection(-1)
		get_viewport().set_input_as_handled()
		return

	if key.keycode == KEY_DOWN or key.keycode == KEY_S:
		_move_selection(1)
		get_viewport().set_input_as_handled()
		return

	if key.keycode == KEY_ENTER or key.keycode == KEY_SPACE:
		_attempt_selected_upgrade()
		get_viewport().set_input_as_handled()
		return

	var shortcut_kind: String = _upgrade_kind_for_number(key)
	if not shortcut_kind.is_empty():
		_select_kind(shortcut_kind)
		_attempt_upgrade(player, shortcut_kind)
		get_viewport().set_input_as_handled()


func _upgrade_kind_for_number(key: InputEventKey) -> String:
	match int(key.keycode):
		KEY_1:
			return "blade"
		KEY_2:
			return "shield"
		KEY_3:
			return "stone"
		KEY_4:
			return "hp"
		KEY_5:
			return "energy"
	return ""


func _set_category(category: String) -> void:
	if category != "player" and category != "items":
		return
	_active_category = category
	_selected_index = 0
	_rebuild_cards()
	_refresh_upgrade_menu(_active_player)
	_animate_category_change()


func _toggle_category() -> void:
	_set_category("items" if _active_category == "player" else "player")


func _category_kinds() -> Array[String]:
	return PLAYER_UPGRADES if _active_category == "player" else ITEM_UPGRADES


func _move_selection(direction: int) -> void:
	var kinds: Array[String] = _category_kinds()
	if kinds.is_empty():
		return
	_selected_index = wrapi(_selected_index + direction, 0, kinds.size())
	_refresh_card_styles()
	_refresh_details(_active_player)


func _select_kind(kind: String) -> void:
	var next_category: String = ""
	if PLAYER_UPGRADES.has(kind):
		next_category = "player"
	elif ITEM_UPGRADES.has(kind):
		next_category = "items"
	else:
		return

	var category_changed: bool = next_category != _active_category
	_active_category = next_category
	var kinds: Array[String] = _category_kinds()
	_selected_index = kinds.find(kind)
	if _selected_index < 0:
		_selected_index = 0

	if category_changed:
		_rebuild_cards()
	else:
		_refresh_card_styles()
	_refresh_upgrade_menu(_active_player)


func _selected_kind() -> String:
	var kinds: Array[String] = _category_kinds()
	if kinds.is_empty():
		return ""
	_selected_index = clampi(_selected_index, 0, kinds.size() - 1)
	return kinds[_selected_index]


func _rebuild_cards() -> void:
	for child in _cards_column.get_children():
		_cards_column.remove_child(child)

	for kind in _category_kinds():
		var button: Button = _card_buttons.get(kind) as Button
		if button == null:
			button = _make_upgrade_card(kind)
		_cards_column.add_child(button)

	_refresh_tabs()
	_refresh_card_styles()


func _refresh_tabs() -> void:
	_set_tab_style(_player_tab, _active_category == "player")
	_set_tab_style(_items_tab, _active_category == "items")


func _set_tab_style(button: Button, active: bool) -> void:
	if button == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#67563a") if active else Color("#2c302d")
	style.border_color = Color("#c0a56b") if active else Color("#4c493f")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_color_override("font_color", Color("#f2dfae") if active else Color("#aaa392"))


func _refresh_card_styles() -> void:
	var selected_kind: String = _selected_kind()
	for kind in _card_buttons.keys():
		var button: Button = _card_buttons[kind] as Button
		if button == null:
			continue
		var selected: bool = String(kind) == selected_kind
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#4a4030") if selected else Color("#202726")
		style.border_color = Color("#d2b16b") if selected else Color("#4f5149")
		style.set_border_width_all(2 if selected else 1)
		style.corner_radius_top_left = 7
		style.corner_radius_top_right = 7
		style.corner_radius_bottom_left = 7
		style.corner_radius_bottom_right = 7
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", _hover_style(selected))
		button.add_theme_stylebox_override("pressed", _pressed_style())
		button.modulate = Color.WHITE if selected else Color(0.88, 0.88, 0.84)


func _hover_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#544733") if selected else Color("#303a36")
	style.border_color = Color("#e0be74")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	return style


func _pressed_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#6a5638")
	style.border_color = Color("#f1cf82")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	return style


func _on_card_pressed(kind: String) -> void:
	_select_kind(kind)
	_attempt_upgrade(_active_player, kind)


func _attempt_selected_upgrade() -> void:
	var kind: String = _selected_kind()
	if kind.is_empty():
		return
	_attempt_upgrade(_active_player, kind)


func _attempt_upgrade(player: Node, kind: String) -> void:
	if player == null or not player.has_method("try_purchase_upgrade"):
		return

	var level: int = int(player.call("get_upgrade_level", kind))
	var cost: int = int(player.call("get_upgrade_cost", kind))
	var available: int = int(player.call("get_score"))

	if level >= 5 or cost < 0:
		_status_label.text = "%s is already at maximum level." % String(UPGRADE_NAMES[kind])
		_refresh_upgrade_menu(player)
		_flash_status(false)
		return

	if available < cost:
		_status_label.text = "Need %d more score for %s." % [cost - available, String(UPGRADE_NAMES[kind])]
		_refresh_upgrade_menu(player)
		_flash_status(false)
		return

	if bool(player.call("try_purchase_upgrade", kind)):
		_status_label.text = "%s strengthened to level %d." % [String(UPGRADE_NAMES[kind]), level + 1]
		_refresh_upgrade_menu(player)
		_flash_status(true)
		_pulse_selected_card()
	else:
		_status_label.text = "Upgrade failed."
		_flash_status(false)


func _show_upgrade_menu(player: Node) -> void:
	_active_player = player
	_active_category = "player"
	_selected_index = 0
	_menu_layer.visible = true
	_rebuild_cards()
	_refresh_upgrade_menu(player)
	_status_label.text = "↑ ↓ Select    ← → / TAB Category    ENTER Upgrade    E Stand"
	_menu_panel.modulate.a = 0.0
	_menu_panel.scale = Vector2(0.985, 0.985)
	_menu_panel.pivot_offset = _menu_panel.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_menu_panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(_menu_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_upgrade_menu() -> void:
	_active_player = null
	if _menu_layer != null:
		_menu_layer.visible = false


func _refresh_upgrade_menu(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return

	_score_label.text = "SCORE  %d" % int(player.call("get_score"))

	for kind in _card_buttons.keys():
		var kind_string := String(kind)
		var level: int = int(player.call("get_upgrade_level", kind_string))
		var cost: int = int(player.call("get_upgrade_cost", kind_string))
		var value_text: String = String(player.call("get_upgrade_value_text", kind_string))

		var title_label: Label = _card_title_labels[kind_string] as Label
		var value_label: Label = _card_value_labels[kind_string] as Label
		var cost_label: Label = _card_cost_labels[kind_string] as Label
		var progress: ProgressBar = _card_progress[kind_string] as ProgressBar

		if title_label != null:
			title_label.text = "%s   Lv %d/5" % [String(UPGRADE_NAMES[kind_string]), level]
		if value_label != null:
			value_label.text = "%s  •  %s" % [String(UPGRADE_SUBTITLES[kind_string]), value_text]
		if cost_label != null:
			cost_label.text = "MAX" if cost < 0 else "%d" % cost
			cost_label.add_theme_color_override(
				"font_color",
				Color("#8fa98d") if cost < 0 else (Color("#e1c279") if int(player.call("get_score")) >= cost else Color("#b96f61"))
			)
		if progress != null:
			progress.value = level

	_refresh_tabs()
	_refresh_card_styles()
	_refresh_details(player)


func _refresh_details(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	var kind: String = _selected_kind()
	if kind.is_empty():
		return

	var level: int = int(player.call("get_upgrade_level", kind))
	var cost: int = int(player.call("get_upgrade_cost", kind))
	var score: int = int(player.call("get_score"))

	_detail_title.text = String(UPGRADE_NAMES[kind])
	_detail_level.text = "%s UPGRADES   •   LEVEL %d / 5" % ["PLAYER" if _active_category == "player" else "ITEM", level]
	_detail_description.text = String(UPGRADE_DESCRIPTIONS[kind])
	_detail_current.text = "CURRENT    %s" % _value_for_level(kind, level)

	if level >= 5 or cost < 0:
		_detail_next.text = "MAXIMUM LEVEL REACHED"
		_detail_cost.text = "No further upgrade"
		detail_cost_color(Color("#8fa98d"))
		_detail_hint.text = "Choose another upgrade"
	else:
		_detail_next.text = "NEXT       %s" % _value_for_level(kind, level + 1)
		_detail_cost.text = "COST       %d SCORE" % cost
		detail_cost_color(Color("#e1c279") if score >= cost else Color("#b96f61"))
		_detail_hint.text = "ENTER / SPACE  Upgrade" if score >= cost else "Need %d more score" % (cost - score)


func _value_for_level(kind: String, level: int) -> String:
	var safe_level: int = clampi(level, 1, 5)
	match kind:
		"blade":
			return "%d damage" % (8 + (safe_level - 1) * 2)
		"shield":
			var multiplier: float = 1.0 - float(safe_level - 1) * 0.08
			return "%d%% guard efficiency" % roundi(100.0 / multiplier)
		"stone":
			return "%d HP healed" % (30 + (safe_level - 1) * 10)
		"hp":
			return "%d max HP" % (100 + (safe_level - 1) * 12)
		"energy":
			return "%d max energy" % (100 + (safe_level - 1) * 12)
	return ""


func _animate_category_change() -> void:
	if _cards_column == null:
		return
	_cards_column.modulate.a = 0.35
	_cards_column.position.x = 8.0 if _active_category == "items" else -8.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_cards_column, "modulate:a", 1.0, 0.12)
	tween.tween_property(_cards_column, "position:x", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _pulse_selected_card() -> void:
	var kind: String = _selected_kind()
	var button: Button = _card_buttons.get(kind) as Button
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.025, 1.025), 0.07)
	tween.tween_property(button, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _flash_status(success: bool) -> void:
	if _status_label == null:
		return
	_status_label.modulate = Color("#a8d49d") if success else Color("#e49b85")
	var tween := create_tween()
	tween.tween_property(_status_label, "modulate", Color.WHITE, 0.35)


func _restore_player(player: Node) -> void:
	var health: Node = player.get_node_or_null("HealthComponent")
	if health != null and health.has_method("restore_full_health"):
		health.call("restore_full_health")

	var energy: Node = player.get_node_or_null("StaminaComponent")
	if energy != null and energy.has_method("restore_full"):
		energy.call("restore_full")


func _activate_checkpoint() -> void:
	var manager: Node = get_node_or_null("/root/MtskhetaTransitionManager")
	if manager != null and manager.has_method("activate_checkpoint"):
		manager.call(
			"activate_checkpoint",
			get_tree().current_scene.scene_file_path,
			spawn_id
		)


func _respawn_scene_enemies() -> void:
	var current: Node = get_tree().current_scene
	if current != null and current.has_method("respawn_enemies"):
		current.call_deferred("respawn_enemies")


func _update_prompt(player: Node) -> void:
	if player != null and player.has_method("is_resting") and bool(player.call("is_resting")):
		_prompt.text = "E  -  Stand up"
	else:
		_prompt.text = "E  -  Rest at the wayside cross"


func _process(delta: float) -> void:
	_elapsed += delta
	if _inside or _lit:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-57,-14,114,15), Color("#4e4c41"))
	draw_rect(Rect2(-50,-24,100,13), Color("#a79a7b"))
	draw_rect(Rect2(-8,-115,16,90), Color("#69685a"))
	draw_rect(Rect2(-29,-94,58,13), Color("#c4b08c"))
	var glow: float = 0.65 + sin(_elapsed * 4.0) * 0.20
	draw_circle(Vector2(36,-53), 17.0, Color("#dba765", 0.20 if _lit else 0.11))
	draw_circle(Vector2(36,-53), 8.0 + glow * 3.0, Color("#e6a95d"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(35,-78), Vector2(27,-50),
			Vector2(37,-37), Vector2(45,-54)
		]),
		Color("#f8d49a")
	)
