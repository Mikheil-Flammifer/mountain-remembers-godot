extends Area2D
## Recoverable score left at Xizane's last safe position after death.

var amount: int = 0
var _clock: float = 0.0
var _label: Label
var _claimed: bool = false


func _ready() -> void:
	add_to_group("lost_score_memory")
	collision_layer = 0
	collision_mask = 1

	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 34.0
	shape_node.shape = shape
	shape_node.position = Vector2(0.0, -28.0)
	add_child(shape_node)

	_label = Label.new()
	_label.position = Vector2(-105.0, -112.0)
	_label.custom_minimum_size = Vector2(210.0, 30.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("#ead6a0"))
	_label.add_theme_color_override("font_outline_color", Color("#202420"))
	_label.add_theme_constant_override("outline_size", 4)
	_label.visible = false
	add_child(_label)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func setup(next_amount: int) -> void:
	amount = maxi(0, next_amount)
	if _label != null:
		_label.text = "Recover %d score" % amount
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _claimed or not body.is_in_group("player"):
		return
	if _label != null:
		_label.text = "Recover %d score" % amount
		_label.visible = true

	# Touching the memory is enough to recover it, like a bloodstain.
	if body.has_method("recover_lost_score"):
		var recovered: int = int(body.call("recover_lost_score"))
		if recovered > 0:
			_claimed = true
			monitoring = false
			var tween := create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.28)
			tween.tween_callback(queue_free)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and _label != null:
		_label.visible = false


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_clock * 2.6)
	var glow := Color(0.76, 0.60, 0.31, 0.10 + pulse * 0.08)
	draw_circle(Vector2(0.0, -25.0), 33.0 + pulse * 4.0, glow)

	var stone := PackedVector2Array([
		Vector2(-18,-8), Vector2(-13,-36), Vector2(-3,-51),
		Vector2(13,-43), Vector2(20,-19), Vector2(11,-2), Vector2(-7,2)
	])
	draw_colored_polygon(stone, Color("#484b42"))
	draw_polyline(stone, Color("#827555"), 2.0, true)
	draw_line(Vector2(-5,-42), Vector2(3,-28), Color("#d5b66d"), 2.0)
	draw_line(Vector2(3,-28), Vector2(-2,-14), Color("#d5b66d"), 2.0)
	draw_line(Vector2(3,-28), Vector2(12,-20), Color("#c99a52"), 1.5)
