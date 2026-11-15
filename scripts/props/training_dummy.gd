extends StaticBody2D

@export var max_hp: int = 5

var hp: int

@onready var sprite: Polygon2D = $Visual

func _ready() -> void:
	hp = max_hp

func take_hit(damage: int, _knockback: Vector2) -> void:
	hp -= damage
	print("[TrainingDummy] Hit! HP: ", hp)

	if sprite != null:
		sprite.modulate = Color(1.3, 0.8, 0.8)

	_flash_reset()

	if hp <= 0:
		queue_free()

func _flash_reset() -> void:
	await get_tree().create_timer(0.10).timeout
	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE