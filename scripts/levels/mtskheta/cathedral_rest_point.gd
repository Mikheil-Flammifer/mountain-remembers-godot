extends Node2D

## Decorative courtyard rest point. Interaction is managed by
## CathedralStoryController and healing by HealthComponent.


func _draw() -> void:
	var stone := Color("#989080")
	var trim := Color("#c4b395")
	var shadow := Color("#444441")
	var ember := Color("#b96b39")

	# Low raised stone platform.
	draw_rect(Rect2(-49, -12, 98, 12), shadow)
	draw_rect(Rect2(-43, -24, 86, 12), stone)
	draw_rect(Rect2(-35, -32, 70, 8), trim)

	# Small cross-shaped stone marker and warm resting lantern.
	draw_rect(Rect2(-5, -105, 10, 73), stone)
	draw_rect(Rect2(-19, -88, 38, 10), trim)
	draw_circle(Vector2(26, -48), 12, shadow)
	draw_circle(Vector2(26, -49), 7, ember)
	draw_colored_polygon(PackedVector2Array([
		Vector2(26, -72), Vector2(19, -51), Vector2(26, -39),
		Vector2(34, -52)
	]), Color("#e2b36e"))
