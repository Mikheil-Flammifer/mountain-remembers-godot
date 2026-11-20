class_name MtskhetaInvestigationNPC
extends Node2D

## Visual NPC used by the Mtskheta investigation system.
## The investigation controller owns dialogue and interaction.

@export var npc_id: String = ""
@export var display_name: String = "Traveler"
@export var cloak_color: Color = Color("#675447")

var _highlighted: bool = false


func _ready() -> void:
	# Level artwork uses z_index = -10.
	# Keep NPCs above that artwork so they remain visible.
	z_index = 1
	queue_redraw()


func set_highlighted(value: bool) -> void:
	if _highlighted == value:
		return

	_highlighted = value
	queue_redraw()


func _draw() -> void:
	var dark := Color("#272b2e")
	var skin := Color("#a88b70")

	# Cloak / body
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-23, 0),
			Vector2(-20, -65),
			Vector2(-12, -85),
			Vector2(11, -85),
			Vector2(22, -60),
			Vector2(26, 0)
		]),
		cloak_color
	)

	# Hair / head silhouette
	draw_circle(
		Vector2(0, -83),
		15,
		dark
	)

	# Face
	draw_circle(
		Vector2(0, -79),
		10,
		skin
	)

	# Hood / hat
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-18, -91),
			Vector2(-8, -107),
			Vector2(10, -105),
			Vector2(20, -88),
			Vector2(0, -93)
		]),
		dark
	)

	# Belt
	draw_line(
		Vector2(-17, -12),
		Vector2(20, -12),
		dark,
		4.0
	)

	# Interaction highlight
	if _highlighted:
		draw_arc(
			Vector2(0, -87),
			27,
			0,
			TAU,
			40,
			Color("#e6c994"),
			2.5
		)