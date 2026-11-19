extends Area2D

## Visible spike hazard. Position, shape, and artwork live in terraces.tscn.
@export var damage: int = 12

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("receive_enemy_hit"):
		body.call("receive_enemy_hit", damage, global_position)
