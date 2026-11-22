extends Area2D
## Reusable spring, shepherd camp, carved milestone, cache and lore inscription.
## Never calls set_resting(): conversation should not seat Xizane.
@export_enum("spring", "milestone", "inscription", "camp", "cache") var kind: String = "milestone"
@export_multiline var message: String = "The river remembers every traveller."

var _player: CharacterBody2D
var _label: Label
var _used: bool = false
var _showing_text: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var detector := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(185.0, 148.0)
	detector.position = Vector2(0.0, -65.0)
	detector.shape = rect
	add_child(detector)
	_label = Label.new()
	_label.position = Vector2(-245.0, -230.0)
	_label.custom_minimum_size = Vector2(490.0, 96.0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color("#f4e4c4"))
	_label.add_theme_color_override("font_outline_color", Color("#2a332b"))
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)
	body_entered.connect(_enter)
	body_exited.connect(_exit)

func _enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body as CharacterBody2D
		_showing_text = false
		_label.text = "E - " + _action_label()
		_label.visible = true

func _exit(body: Node2D) -> void:
	if body == _player:
		_player = null
		_label.visible = false
		_showing_text = false

func _action_label() -> String:
	match kind:
		"spring": return "Drink from the mountain spring"
		"cache": return "Open the supply cache"
		"camp": return "Listen to the shepherd"
		"inscription": return "Read the weathered inscription"
	return "Inspect the waystone"

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_player) or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or not (key.physical_keycode == KEY_E or key.keycode == KEY_E):
		return
	_label.text = message
	_showing_text = true
	if kind in ["spring", "cache"] and not _used:
		var health: Node = _player.get_node_or_null("HealthComponent")
		if health != null and health.has_method("restore_full_health"):
			health.call("restore_full_health")
		_used = true
	get_viewport().set_input_as_handled()
	queue_redraw()

func _draw() -> void:
	match kind:
		"spring":
			draw_colored_polygon(PackedVector2Array([Vector2(-67,0),Vector2(-55,-45),Vector2(-9,-61),Vector2(39,-49),Vector2(62,-3),Vector2(69,0)]), Color("#68776e"))
			draw_circle(Vector2(0,-17), 23.0, Color("#7da9a0"))
			draw_line(Vector2(-12,-40),Vector2(0,-18),Color("#d0e4cd"),3.0)
		"cache":
			draw_rect(Rect2(-44,-46,88,46),Color("#5b4534"))
			draw_rect(Rect2(-48,-56,96,14),Color("#8b6b4a"))
			draw_rect(Rect2(-6,-52,13,48),Color("#c0a173"))
		"camp":
			draw_colored_polygon(PackedVector2Array([Vector2(-88,0),Vector2(0,-113),Vector2(93,0)]),Color("#a18c69"))
			draw_colored_polygon(PackedVector2Array([Vector2(0,-112),Vector2(36,0),Vector2(0,0)]),Color("#77684f"))
			draw_rect(Rect2(-13,-47,26,47),Color("#343a35"))
		"inscription":
			draw_colored_polygon(PackedVector2Array([Vector2(-44,0),Vector2(-42,-105),Vector2(0,-116),Vector2(43,-103),Vector2(42,0)]),Color("#858777"))
			for row in range(4):
				var y: float = -85.0 + float(row)*17.0
				draw_line(Vector2(-23,y),Vector2(29-float(row)*5.0,y),Color("#c8b696"),2.0)
		_:
			draw_rect(Rect2(-42,-90,84,90),Color("#777b6b"))
			draw_rect(Rect2(-45,-98,90,13),Color("#c0b095"))
			draw_line(Vector2(-12,-72),Vector2(13,-72),Color("#e0c99a"),2.2)
			draw_line(Vector2(0,-86),Vector2(0,-57),Color("#e0c99a"),2.2)
