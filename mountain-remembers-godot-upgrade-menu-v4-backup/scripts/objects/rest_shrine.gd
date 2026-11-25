extends Area2D
## Wayside rest point.
## E sits/rests; E again stands. While seated, 1-5 buy upgrades with score.
## Resting heals HP, restores energy, saves the checkpoint and respawns enemies.

@export var spawn_id: String = "rest_1"

const UPGRADE_ORDER: Array[String] = ["blade", "shield", "stone", "hp", "energy"]
const UPGRADE_NAMES: Dictionary = {
	"blade": "Mountain Blade",
	"shield": "Shield",
	"stone": "Healing Stone",
	"hp": "Vitality / HP",
	"energy": "Endurance / Energy",
}

var _inside: bool = false
var _prompt: Label
var _lit: bool = false
var _elapsed: float = 0.0
var _menu_layer: CanvasLayer
var _menu_panel: PanelContainer
var _score_label: Label
var _status_label: Label
var _upgrade_labels: Array[Label] = []


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
	_prompt.position = Vector2(-150, -177)
	_prompt.custom_minimum_size = Vector2(300, 34)
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

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(root)

	_menu_panel = PanelContainer.new()
	_menu_panel.set_anchors_preset(Control.PRESET_CENTER)
	_menu_panel.offset_left = -315.0
	_menu_panel.offset_right = 315.0
	_menu_panel.offset_top = -235.0
	_menu_panel.offset_bottom = 235.0
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_menu_panel)

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.025, 0.030, 0.032, 0.96)
	frame.border_color = Color("#77664a")
	frame.set_border_width_all(2)
	frame.corner_radius_top_left = 8
	frame.corner_radius_top_right = 8
	frame.corner_radius_bottom_left = 8
	frame.corner_radius_bottom_right = 8
	frame.content_margin_left = 24
	frame.content_margin_right = 24
	frame.content_margin_top = 20
	frame.content_margin_bottom = 20
	_menu_panel.add_theme_stylebox_override("panel", frame)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	_menu_panel.add_child(layout)

	var title := Label.new()
	title.text = "WAYSIDE REST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#ead7a5"))
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Spend score earned from defeated enemies"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#aaa58f"))
	layout.add_child(subtitle)

	_score_label = Label.new()
	_score_label.text = "SCORE  0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 18)
	_score_label.add_theme_color_override("font_color", Color("#d7bb75"))
	layout.add_child(_score_label)

	var divider := HSeparator.new()
	layout.add_child(divider)

	for i in range(UPGRADE_ORDER.size()):
		var line := Label.new()
		line.custom_minimum_size = Vector2(560, 42)
		line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_theme_font_size_override("font_size", 16)
		line.add_theme_color_override("font_color", Color("#e1d7bd"))
		layout.add_child(line)
		_upgrade_labels.append(line)

	_status_label = Label.new()
	_status_label.text = "1-5 upgrade   •   E stand"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color("#aaa58f"))
	layout.add_child(_status_label)

	_menu_panel.visible = false


func _on_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = true
		_prompt.visible = true
		_update_prompt(body)


func _on_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
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

	var index: int = _upgrade_index_for_key(key)
	if index < 0 or index >= UPGRADE_ORDER.size():
		return

	var kind: String = UPGRADE_ORDER[index]
	_attempt_upgrade(player, kind)
	get_viewport().set_input_as_handled()


func _upgrade_index_for_key(key: InputEventKey) -> int:
	var code: int = int(key.keycode)
	if code == KEY_1:
		return 0
	if code == KEY_2:
		return 1
	if code == KEY_3:
		return 2
	if code == KEY_4:
		return 3
	if code == KEY_5:
		return 4
	return -1


func _attempt_upgrade(player: Node, kind: String) -> void:
	if not player.has_method("try_purchase_upgrade"):
		return
	var level: int = int(player.call("get_upgrade_level", kind))
	var cost: int = int(player.call("get_upgrade_cost", kind))
	var available: int = int(player.call("get_score"))

	if level >= 5 or cost < 0:
		_status_label.text = "%s is already at maximum level." % String(UPGRADE_NAMES[kind])
		_refresh_upgrade_menu(player)
		return
	if available < cost:
		_status_label.text = "Need %d more score for %s." % [cost - available, String(UPGRADE_NAMES[kind])]
		_refresh_upgrade_menu(player)
		return

	if bool(player.call("try_purchase_upgrade", kind)):
		_status_label.text = "%s upgraded to level %d." % [String(UPGRADE_NAMES[kind]), level + 1]
	else:
		_status_label.text = "Upgrade failed."
	_refresh_upgrade_menu(player)


func _show_upgrade_menu(player: Node) -> void:
	_menu_panel.visible = true
	_status_label.text = "1-5 upgrade   •   E stand"
	_refresh_upgrade_menu(player)


func _hide_upgrade_menu() -> void:
	if _menu_panel != null:
		_menu_panel.visible = false


func _refresh_upgrade_menu(player: Node) -> void:
	if player == null:
		return
	_score_label.text = "SCORE  %d" % int(player.call("get_score"))

	for i in range(UPGRADE_ORDER.size()):
		var kind: String = UPGRADE_ORDER[i]
		var level: int = int(player.call("get_upgrade_level", kind))
		var cost: int = int(player.call("get_upgrade_cost", kind))
		var value_text: String = String(player.call("get_upgrade_value_text", kind))
		var cost_text: String = "MAX" if cost < 0 else "Cost %d" % cost
		_upgrade_labels[i].text = "%d   %s   Lv %d/5   •   %s   •   %s" % [
			i + 1,
			String(UPGRADE_NAMES[kind]),
			level,
			value_text,
			cost_text,
		]


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
