extends CanvasLayer

## Compact upper-left HP/energy display plus illustrated equipment medallions in
## the lower-left: healing stone above, shield left, Mountain Blade right.

const EQUIPMENT_ICON_SCRIPT = preload("res://scripts/ui/equipment_icon.gd")

var _player: Node
var _health: Node
var _stamina: Node
var _hp_bar: ProgressBar
var _hp_label: Label
var _energy_bar: ProgressBar
var _energy_label: Label
var _score_label: Label
var _stone_icon: Control
var _shield_icon: Control
var _blade_icon: Control


func _ready() -> void:
	layer = 100
	_build_ui()
	call_deferred("_connect_to_player")


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_status_panel(root)
	_build_equipment_cluster(root)


func _build_status_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 20)
	panel.custom_minimum_size = Vector2(360, 126)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.025, 0.032, 0.035, 0.91)
	frame.border_color = Color("#6e6047")
	frame.set_border_width_all(2)
	frame.corner_radius_top_left = 7
	frame.corner_radius_top_right = 7
	frame.corner_radius_bottom_left = 7
	frame.corner_radius_bottom_right = 7
	frame.content_margin_left = 15
	frame.content_margin_right = 15
	frame.content_margin_top = 9
	frame.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", frame)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var name_label := Label.new()
	name_label.text = "XIZANE"
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color("#e5d2a5"))
	header.add_child(name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_hp_label = Label.new()
	_hp_label.text = "100 / 100"
	_hp_label.add_theme_font_size_override("font_size", 12)
	_hp_label.add_theme_color_override("font_color", Color("#decfc4"))
	header.add_child(_hp_label)

	_hp_bar = _make_bar(Vector2(326, 23), Color("#982f33"), Color("#21191a"), 5)
	layout.add_child(_hp_bar)

	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 8)
	layout.add_child(energy_row)

	_energy_label = Label.new()
	_energy_label.text = "ENERGY"
	_energy_label.custom_minimum_size = Vector2(70, 16)
	_energy_label.add_theme_font_size_override("font_size", 10)
	_energy_label.add_theme_color_override("font_color", Color("#bdc9b4"))
	energy_row.add_child(_energy_label)

	_energy_bar = _make_bar(Vector2(248, 13), Color("#708d68"), Color("#18201c"), 4)
	energy_row.add_child(_energy_bar)

	_score_label = Label.new()
	_score_label.text = "SCORE  0"
	_score_label.add_theme_font_size_override("font_size", 12)
	_score_label.add_theme_color_override("font_color", Color("#d1b66f"))
	layout.add_child(_score_label)


func _build_equipment_cluster(root: Control) -> void:
	_stone_icon = _make_equipment_icon(root, Vector2(69, -188), "stone", "R", "HEALING STONE")
	_shield_icon = _make_equipment_icon(root, Vector2(18, -101), "shield", "G", "SHIELD")
	_blade_icon = _make_equipment_icon(root, Vector2(121, -101), "sword", "H", "BLADE")


func _make_equipment_icon(
	root: Control,
	bottom_left_offset: Vector2,
	kind: String,
	key_text: String,
	caption: String
) -> Control:
	var icon := EQUIPMENT_ICON_SCRIPT.new() as Control
	icon.set("icon_type", kind)
	icon.set("key_text", key_text)
	icon.set("caption", caption)
	icon.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	icon.offset_left = bottom_left_offset.x
	icon.offset_right = bottom_left_offset.x + 74.0
	icon.offset_top = bottom_left_offset.y
	icon.offset_bottom = bottom_left_offset.y + 96.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon)
	return icon


func _make_bar(size: Vector2, fill_color: Color, background_color: Color, radius: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = size
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false

	var background := StyleBoxFlat.new()
	background.bg_color = background_color
	background.border_color = Color("#4d4438")
	background.set_border_width_all(1)
	background.corner_radius_top_left = radius
	background.corner_radius_top_right = radius
	background.corner_radius_bottom_left = radius
	background.corner_radius_bottom_right = radius

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = radius
	fill.corner_radius_top_right = radius
	fill.corner_radius_bottom_left = radius
	fill.corner_radius_bottom_right = radius

	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _connect_to_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("HUD: Xizane not found in player group")
		return

	_health = _player.get_node_or_null("HealthComponent")
	_stamina = _player.get_node_or_null("StaminaComponent")

	if _health != null and _health.has_signal("health_changed"):
		var hp_callback := Callable(self, "_update_health")
		if not _health.is_connected("health_changed", hp_callback):
			_health.connect("health_changed", hp_callback)
		_update_health(int(_health.get("current_health")), int(_health.get("max_health")))

	if _stamina != null and _stamina.has_signal("stamina_changed"):
		var energy_callback := Callable(self, "_update_energy")
		if not _stamina.is_connected("stamina_changed", energy_callback):
			_stamina.connect("stamina_changed", energy_callback)
		_update_energy(float(_stamina.get("current_stamina")), float(_stamina.get("max_stamina")))

	if _player.has_signal("healing_stones_changed"):
		var stones_callback := Callable(self, "_update_stones")
		if not _player.is_connected("healing_stones_changed", stones_callback):
			_player.connect("healing_stones_changed", stones_callback)
		_update_stones(int(_player.get("healing_stones")))

	if _player.has_signal("shield_state_changed"):
		var shield_callback := Callable(self, "_update_shield")
		if not _player.is_connected("shield_state_changed", shield_callback):
			_player.connect("shield_state_changed", shield_callback)
		_update_shield(false)

	if _player.has_signal("score_changed"):
		var score_callback := Callable(self, "_update_score")
		if not _player.is_connected("score_changed", score_callback):
			_player.connect("score_changed", score_callback)
		_update_score(int(_player.call("get_score")))

	if _player.has_signal("upgrades_changed"):
		var upgrades_callback := Callable(self, "_update_upgrade_levels")
		if not _player.is_connected("upgrades_changed", upgrades_callback):
			_player.connect("upgrades_changed", upgrades_callback)
		_update_upgrade_levels()


func _update_health(current: int, maximum: int) -> void:
	_hp_bar.max_value = maxi(maximum, 1)
	_hp_bar.value = current
	_hp_label.text = "%d / %d" % [current, maximum]


func _update_energy(current: float, maximum: float) -> void:
	_energy_bar.max_value = maxf(maximum, 1.0)
	_energy_bar.value = current
	_energy_label.text = "ENERGY %d" % int(current)


func _update_stones(current: int) -> void:
	if _stone_icon != null and _stone_icon.has_method("set_count"):
		_stone_icon.call("set_count", current)
	_stone_icon.modulate = Color.WHITE if current > 0 else Color(0.58, 0.58, 0.58, 0.72)


func _update_shield(active: bool) -> void:
	if _shield_icon != null and _shield_icon.has_method("set_state"):
		_shield_icon.call("set_state", active)


func _update_score(current: int) -> void:
	if _score_label != null:
		_score_label.text = "SCORE  %d" % current


func _update_upgrade_levels() -> void:
	if _player == null:
		return
	if _stone_icon != null and _stone_icon.has_method("set_level"):
		_stone_icon.call("set_level", int(_player.call("get_upgrade_level", "stone")))
	if _shield_icon != null and _shield_icon.has_method("set_level"):
		_shield_icon.call("set_level", int(_player.call("get_upgrade_level", "shield")))
	if _blade_icon != null and _blade_icon.has_method("set_level"):
		_blade_icon.call("set_level", int(_player.call("get_upgrade_level", "blade")))
