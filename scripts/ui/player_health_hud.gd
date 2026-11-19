
extends CanvasLayer

var _health: HealthComponent
var _bar: ProgressBar
var _hp_label: Label
var _stamina_bar: ProgressBar
var _stamina_label: Label


func _ready() -> void:
	layer = 100
	_build_ui()
	call_deferred("_connect_to_player")
	call_deferred("_connect_stamina")


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(300, 90)
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.9)
	style.border_color = Color(0.58, 0.44, 0.30)
	style.set_border_width_all(2)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var name_label := Label.new()
	name_label.text = "XIZANE"
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override(
		"font_color", Color(0.92, 0.82, 0.63)
	)
	header.add_child(name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_hp_label = Label.new()
	_hp_label.text = "100 / 100 HP"
	header.add_child(_hp_label)

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(270, 22)
	_bar.min_value = 0
	_bar.max_value = 100
	_bar.value = 100
	_bar.show_percentage = false

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.19, 0.19, 0.20)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.72, 0.12, 0.15)

	_bar.add_theme_stylebox_override(
		"background", background
	)
	_bar.add_theme_stylebox_override(
		"fill", fill
	)

	layout.add_child(_bar)
	_stamina_label = Label.new()
	_stamina_label.text = "STAMINA"
	layout.add_child(_stamina_label)
	_stamina_bar = ProgressBar.new()
	_stamina_bar.custom_minimum_size = Vector2(270, 12)
	_stamina_bar.show_percentage = false
	_stamina_bar.max_value = 100
	_stamina_bar.value = 100
	layout.add_child(_stamina_bar)


func _connect_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		push_warning("HUD: Xizane not found in player group")
		return

	_health = player.get_node_or_null(
		"HealthComponent"
	) as HealthComponent

	if _health == null:
		push_warning("HUD: player HealthComponent missing")
		return

	if not _health.health_changed.is_connected(
		_update_health
	):
		_health.health_changed.connect(_update_health)

	_update_health(
		_health.current_health,
		_health.max_health
	)


func _update_health(current: int, maximum: int) -> void:
	_bar.max_value = maxi(maximum, 1)
	_bar.value = current
	_hp_label.text = "%d / %d HP" % [current, maximum]

func _connect_stamina() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var stamina: StaminaComponent = player.get_node_or_null("StaminaComponent") as StaminaComponent
	if stamina != null:
		stamina.stamina_changed.connect(_update_stamina)
		_update_stamina(stamina.current_stamina, stamina.max_stamina)

func _update_stamina(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
	_stamina_label.text = "STAMINA  %d / %d" % [int(current), int(maximum)]
