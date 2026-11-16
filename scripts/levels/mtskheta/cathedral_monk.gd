extends Node2D

## Visual-only monk. CathedralStoryController handles E and dialogue,
## preventing competing input handlers.


func _draw() -> void:
	var dark := Color("#292c2d")
	var mantle := Color("#474640")
	var fabric := Color("#6d6357")
	var skin := Color("#aa9077")

	draw_colored_polygon(PackedVector2Array([
		Vector2(-23, 0), Vector2(-20, -66), Vector2(-12, -89),
		Vector2(13, -89), Vector2(22, -64), Vector2(26, 0)
	]), mantle)
	draw_rect(Rect2(-14, -40, 29, 4), fabric)
	draw_circle(Vector2(0, -85), 17, dark)
	draw_circle(Vector2(0, -82), 10, skin)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24, -69), Vector2(-13, -105), Vector2(13, -104),
		Vector2(25, -69), Vector2(8, -73), Vector2(0, -93),
		Vector2(-9, -74)
	]), dark)
	draw_line(Vector2(16, -56), Vector2(20, -19), fabric, 8.0)
	draw_line(Vector2(0, -35), Vector2(0, 0), fabric, 2.0)
