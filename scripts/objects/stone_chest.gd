extends Area2D

@export var pickup_id: String = ""
@export var prompt_text: String = "E - Open chest"
@export_multiline var description: String = "Inside the chest you find a healing stone."
@export var input_action: String = "interact"

var _player: Node = null
var _opened: bool = false
var _prompt: Label
var _message: Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.text = prompt_text
	_prompt.visible = false
	_prompt.position = Vector2(-86.0, -100.0)
	_prompt.size = Vector2(220.0, 24.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 13)
	_prompt.add_theme_color_override("font_color", Color("#f4e5c7"))
	_prompt.add_theme_color_override("font_outline_color", Color("#2a241d"))
	_prompt.add_theme_constant_override("outline_size", 3)
	add_child(_prompt)
	_message = Label.new()
	_message.visible = false
	_message.position = Vector2(-210.0, -146.0)
	_message.size = Vector2(420.0, 56.0)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_size_override("font_size", 13)
	_message.add_theme_color_override("font_color", Color("#f4e5c7"))
	_message.add_theme_color_override("font_outline_color", Color("#2a241d"))
	_message.add_theme_constant_override("outline_size", 3)
	add_child(_message)
	if _is_already_collected():
		_opened = true
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _player == null or _opened:
		return
	if input_action != "" and event.is_action_pressed(input_action):
		_open_chest()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		_player = body
		if not _opened:
			_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_prompt.visible = false

func _is_already_collected() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("has_collected_healing_stone"):
		return bool(player.call("has_collected_healing_stone", pickup_id))
	return XizaneProgressionStore.has_collected(get_tree().root, pickup_id)

func _open_chest() -> void:
	if _player == null:
		return
	var success: bool = false
	if _player.has_method("collect_healing_stone"):
		success = bool(_player.call("collect_healing_stone", pickup_id))
	elif _player.has_method("add_healing_stone"):
		success = bool(_player.call("add_healing_stone", 1))
	if success:
		_opened = true
		_prompt.visible = false
		_message.text = description
		_message.visible = true
		var tween := create_tween()
		tween.tween_interval(2.1)
		tween.tween_callback(func(): _message.visible = false)
		queue_redraw()

func _draw() -> void:
	var wood_dark := Color("#5b3d22")
	var wood_mid := Color("#7d5731")
	var wood_light := Color("#966740")
	var metal := Color("#b89a61")
	var metal_shadow := Color("#7f6640")
	var inner := Color("#251c16")
	var lid_top: float = -34.0
	if _opened:
		lid_top = -66.0

	# Feet / shadow.
	draw_rect(Rect2(-44.0, 36.0, 88.0, 6.0), Color("#1e1712", 0.35))
	for x in [-34.0, 26.0]:
		draw_rect(Rect2(x, 28.0, 10.0, 12.0), wood_dark)

	# Base chest body.
	draw_rect(Rect2(-48.0, -6.0, 96.0, 42.0), wood_dark)
	draw_rect(Rect2(-42.0, -1.0, 84.0, 32.0), wood_mid)
	draw_rect(Rect2(-48.0, 6.0, 96.0, 5.0), metal)
	draw_rect(Rect2(-48.0, 22.0, 96.0, 4.0), metal_shadow)
	for x in [-30.0, 0.0, 30.0]:
		draw_rect(Rect2(x - 3.0, -6.0, 6.0, 42.0), metal_shadow)
	# Lock plate and handles.
	draw_rect(Rect2(-8.0, 6.0, 16.0, 18.0), metal)
	draw_rect(Rect2(-4.0, 10.0, 8.0, 8.0), metal_shadow)
	for x in [-41.0, 33.0]:
		draw_arc(Vector2(x, 12.0), 8.0, 0.1 * PI, 0.9 * PI, 10, metal, 2.0)

	# Lid.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-50.0, -6.0), Vector2(-34.0, lid_top), Vector2(34.0, lid_top), Vector2(50.0, -6.0)
	]), wood_mid)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-42.0, -8.0), Vector2(-28.0, lid_top + 8.0), Vector2(28.0, lid_top + 8.0), Vector2(42.0, -8.0)
	]), wood_light)
	draw_line(Vector2(-30.0, lid_top + 12.0), Vector2(30.0, lid_top + 12.0), metal, 2.4)
	for x in [-28.0, 28.0]:
		draw_circle(Vector2(x, -10.0), 3.2, metal_shadow)

	if _opened:
		draw_rect(Rect2(-34.0, -2.0, 68.0, 16.0), inner)
		draw_circle(Vector2(0.0, 4.0), 9.0, Color("#d7d9df", 0.96))
		draw_circle(Vector2(0.0, 4.0), 16.0, Color("#efe0aa", 0.20))
		# Cloth / cedar lining.
		draw_rect(Rect2(-30.0, 8.0, 60.0, 6.0), Color("#54432c"))
