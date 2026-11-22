extends Area2D
## Friendly Zhinvali NPC: local rumor/dialogue. No sit/rest animation.
@export var speaker_name: String = "Mountain Shepherd"
@export var dialogue: PackedStringArray = PackedStringArray([
	"The pines hide paths that maps forget.",
	"A young woman passed before dawn. She walked alone.",
	"If you are searching for her, ask those on the high ridge."
])
@export var cloak_color: Color = Color("#5d6454")

var _player: CharacterBody2D
var _label: Label
var _line: int = 0
var _inside: bool = false
var _clock: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var sensor := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(160.0, 150.0)
	sensor.position = Vector2(0.0, -68.0)
	sensor.shape = box
	add_child(sensor)
	_label = Label.new()
	_label.position = Vector2(-260.0, -220.0)
	_label.custom_minimum_size = Vector2(520.0, 95.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color("#f1e3c7"))
	_label.add_theme_color_override("font_outline_color", Color("#28342b"))
	_label.add_theme_constant_override("outline_size", 5)
	_label.visible = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	body_entered.connect(_enter)
	body_exited.connect(_leave)

func _enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body as CharacterBody2D
		_inside = true
		_line = 0
		_label.visible = true
		_label.text = "E - Talk to " + speaker_name

func _leave(body: Node2D) -> void:
	if body == _player:
		_inside = false
		_player = null
		_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _inside or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and (key.keycode == KEY_E or key.physical_keycode == KEY_E):
		if dialogue.is_empty():
			return
		_label.text = speaker_name + ": " + dialogue[_line] + "\n[E] Continue"
		_line = (_line + 1) % dialogue.size()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_clock += delta
	if int(_clock * 5.0) != int((_clock - delta) * 5.0):
		queue_redraw()

func _draw() -> void:
	var sway: float = sin(_clock * 1.6) * 1.4
	# Staff, mountain wool cloak and shoulder satchel silhouette.
	draw_line(Vector2(28.0,-92.0),Vector2(34.0,0.0),Color("#6e5944"),5.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24.0,0.0),Vector2(-20.0,-69.0),Vector2(-8.0,-97.0+sway),
		Vector2(11.0,-97.0+sway),Vector2(22.0,-71.0),Vector2(26.0,0.0)
	]),cloak_color)
	draw_rect(Rect2(-17.0,-41.0,33.0,6.0),Color("#806849"))
	draw_circle(Vector2(0.0,-103.0+sway),16.0,Color("#3c3b36"))
	draw_circle(Vector2(0.0,-102.0+sway),9.0,Color("#b29a7d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17.0,-101.0),Vector2(-10.0,-121.0),
		Vector2(12.0,-120.0),Vector2(20.0,-100.0),Vector2(9.0,-111.0)
	]),Color("#383c39"))
	draw_rect(Rect2(-31.0,-52.0,13.0,29.0),Color("#71553f"))
