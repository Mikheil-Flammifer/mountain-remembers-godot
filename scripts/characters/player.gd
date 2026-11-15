
class_name XizanePlayer
extends CharacterBody2D

## Xizane — the playable protagonist.
## Movement and health remain separate components.

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 6.0

	if health != null:
		health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	movement.physics_tick(self, delta)


func _on_died() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
