class_name MtskhetaInvestigationNPC
extends Node2D

## Visual NPC; controller owns interaction. Drawn behind the player (z=0).
@export var npc_id: String = ""
@export var display_name: String = "Traveler"
@export var cloak_color: Color = Color("#675447")

var _highlighted: bool = false

func _ready() -> void:
	z_index = -2
	queue_redraw()

func set_highlighted(value: bool) -> void:
	if _highlighted == value:
		return
	_highlighted = value
	queue_redraw()

func _draw() -> void:
	var dark := Color("#272b2e")
	var skin := Color("#a88b70")
	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, 0), Vector2(-20, -65), Vector2(-12, -85),
		Vector2(11, -85), Vector2(22, -60), Vector2(26, 0)
	]), cloak_color)
	draw_circle(Vector2(0, -83), 15, dark)
	draw_circle(Vector2(0, -79), 10, skin)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -91), Vector2(-8, -107), Vector2(10, -105),
		Vector2(20, -88), Vector2(0, -93)
	]), dark)
	draw_line(Vector2(-17, -12), Vector2(20, -12), dark, 4.0)
	if _highlighted:
		draw_arc(Vector2(0, -87), 27, 0, TAU, 40, Color("#e6c994"), 2.5)
