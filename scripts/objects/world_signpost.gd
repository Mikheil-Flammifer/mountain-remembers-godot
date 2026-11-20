class_name WorldSignpost
extends Node2D

## Reusable physical direction sign.
## World-space object — not HUD text.

@export var inscription: String = "ROAD"

# 0 = left, 1 = right
@export_enum("Left", "Right") var direction: int = 1

@export var plank_width: float = 150.0
@export var plank_height: float = 34.0
@export var post_height: float = 195.0

@export var wood_color: Color = Color("#715039")
@export var wood_dark: Color = Color("#49352a")
@export var wood_light: Color = Color("#9b7654")
@export var text_color: Color = Color("#e4d2ad")

@onready var inscription_label: Label = $Inscription


func _ready() -> void:
	# Background = -10
	# Sign = 0
	# NPC = 1
	# Xizane = 2
	z_index = 0

	_update_label()
	queue_redraw()


func _update_label() -> void:
	if inscription_label == null:
		return

	inscription_label.text = inscription

	var board_top: float = -post_height

	inscription_label.position = Vector2(
		-plank_width * 0.5 + 11.0,
		board_top + 7.0
	)

	inscription_label.size = Vector2(
		plank_width - 22.0,
		plank_height - 10.0
	)

	inscription_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inscription_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	inscription_label.add_theme_color_override(
		"font_color",
		text_color
	)

	inscription_label.add_theme_color_override(
		"font_outline_color",
		wood_dark
	)

	inscription_label.add_theme_constant_override(
		"outline_size",
		3
	)

	inscription_label.add_theme_font_size_override(
		"font_size",
		15
	)

	inscription_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var board_top: float = -post_height
	var half_width: float = plank_width * 0.5
	var arrow_size: float = 26.0

	# ------------------------------------------------------------
	# Vertical wooden post
	# ------------------------------------------------------------

	draw_rect(
		Rect2(
			-7.0,
			board_top + 24.0,
			14.0,
			post_height - 24.0
		),
		wood_dark
	)

	draw_rect(
		Rect2(
			-4.0,
			board_top + 24.0,
			7.0,
			post_height - 24.0
		),
		wood_color
	)

	# Small stone at the base
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-16.0, 0.0),
			Vector2(-12.0, -10.0),
			Vector2(-2.0, -16.0),
			Vector2(13.0, -10.0),
			Vector2(18.0, 0.0)
		]),
		Color("#71695e")
	)

	# ------------------------------------------------------------
	# Direction plank
	# ------------------------------------------------------------

	var points := PackedVector2Array()

	if direction == 1:
		# Right-pointing plank.
		points = PackedVector2Array([
			Vector2(-half_width, board_top),
			Vector2(half_width - arrow_size, board_top),
			Vector2(half_width + arrow_size, board_top + plank_height * 0.5),
			Vector2(half_width - arrow_size, board_top + plank_height),
			Vector2(-half_width, board_top + plank_height)
		])
	else:
		# Left-pointing plank.
		points = PackedVector2Array([
			Vector2(half_width, board_top),
			Vector2(-half_width + arrow_size, board_top),
			Vector2(-half_width - arrow_size, board_top + plank_height * 0.5),
			Vector2(-half_width + arrow_size, board_top + plank_height),
			Vector2(half_width, board_top + plank_height)
		])

	draw_colored_polygon(
		points,
		wood_color
	)

	# Wooden top highlight.
	draw_line(
		Vector2(-half_width + 6.0, board_top + 4.0),
		Vector2(half_width - arrow_size, board_top + 4.0),
		wood_light,
		2.0
	)

	# Wood grain.
	for i in range(3):
		var grain_y: float = board_top + 12.0 + float(i) * 10.0

		draw_line(
			Vector2(-half_width + 13.0, grain_y),
			Vector2(half_width - 35.0, grain_y + float(i % 2) * 2.0),
			Color(wood_dark, 0.38),
			1.0
		)

	# Wooden peg.
	draw_circle(
		Vector2(0.0, board_top + plank_height * 0.5),
		3.5,
		wood_dark
	)