extends Area2D
## Interactive wayside rest point.
## E sits/rests; E again stands.

@export var spawn_id: String = "rest_1"

var _player: XizanePlayer
var _prompt: Label
var _lit: bool = false
var _elapsed: float = 0.0

var _upgrade_menu: ShrineUpgradeMenu


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

	_upgrade_menu = ShrineUpgradeMenu.new()
	add_child(_upgrade_menu)
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)


func _on_entered(body: Node2D) -> void:
	if body is XizanePlayer:
		_player = body
		_prompt.visible = true
		_update_prompt()


func _on_exited(body: Node2D) -> void:
	if body != _player:
		return
	if _player.is_resting():
		_player.set_resting(false)
	_player = null
	_prompt.visible = false
	_upgrade_menu.close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_player) or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_E and event.physical_keycode != KEY_E:
		return
	if _player.health.is_dead:
		return

	if _player.is_resting():
		_player.set_resting(false)
		_upgrade_menu.close_menu()
	else:
		_player.set_resting(true)
		_player.health.restore_full_health()
		_player.stamina.restore_full()
		_activate_checkpoint()
		_respawn_scene_enemies()
		_lit = true
		_upgrade_menu.open_for(_player)

	_update_prompt()
	get_viewport().set_input_as_handled()
	queue_redraw()


func _activate_checkpoint() -> void:
	var manager: Node = get_node_or_null("/root/MtskhetaTransitionManager")
	if get_tree().current_scene != null and manager != null and manager.has_method("activate_checkpoint"):
		manager.call(
			"activate_checkpoint",
			get_tree().current_scene.scene_file_path,
			spawn_id
		)


func _respawn_scene_enemies() -> void:
	var current: Node = get_tree().current_scene
	if current != null and current.has_method("respawn_enemies"):
		current.call_deferred("respawn_enemies")


func _update_prompt() -> void:
	if _player.is_resting():
		_prompt.text = "E  -  Stand up"
	else:
		_prompt.text = "E  -  Rest at the wayside cross"


func _process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(_player) or _lit:
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
