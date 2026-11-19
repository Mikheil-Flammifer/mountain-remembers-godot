extends Area2D
## Optional environmental story inscription at each sub-area's last stretch.
@export_multiline var message: String = "A road remembered in stone."
var _inside: bool = false
var _label: Label

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var sensor := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(180, 144)
	sensor.shape = rectangle
	sensor.position = Vector2(0,-74)
	add_child(sensor)
	_label = Label.new()
	_label.position = Vector2(-225,-205)
	_label.custom_minimum_size = Vector2(450,86)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color("#f4e3bf"))
	_label.text = "E - Read the inscription"
	_label.visible = false
	add_child(_label)
	body_entered.connect(_enter)
	body_exited.connect(_exit)

func _enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = true
		_label.text = "E - Read the inscription"
		_label.visible = true

func _exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = false
		_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _inside or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and (key.physical_keycode == KEY_E or key.keycode == KEY_E):
		_label.text = message
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(-43,-79,86,79),Color("#65675a"))
	draw_rect(Rect2(-47,-85,94,14),Color("#aba080"))
	draw_line(Vector2(-28,-59),Vector2(28,-59),Color("#c4ae88"),2)
	for i in range(3):
		draw_line(Vector2(-25,-42 + i*13),Vector2(24 - i*6,-42 + i*13),Color("#b7ab8c"),2)
