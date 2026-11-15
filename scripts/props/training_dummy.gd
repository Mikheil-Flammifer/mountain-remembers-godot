
extends StaticBody2D

@export var max_hp: int = 5

@onready var visual: Polygon2D = $Visual

var hp: int = 5
var _flash_tween: Tween


func _ready() -> void:
	hp = max_hp


func take_hit(
	amount: int,
	_knockback: Vector2
) -> void:
	if hp <= 0:
		return

	hp = maxi(hp - amount, 0)

	print(
		"[TrainingDummy] Hit! HP: %d/%d"
		% [hp, max_hp]
	)

	_flash()

	if hp <= 0:
		print("[TrainingDummy] Defeated!")
		queue_free()


func _flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()

	visual.modulate = Color(1.5, 0.55, 0.55)

	_flash_tween = create_tween()
	_flash_tween.tween_property(
		visual,
		"modulate",
		Color.WHITE,
		0.16
	)
