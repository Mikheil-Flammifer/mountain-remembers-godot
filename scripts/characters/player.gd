
class_name XizanePlayer
extends CharacterBody2D

## Main playable character.
## Coordinates the player's components without
## implementing their internal mechanics.

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
    health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
    movement.physics_tick(self, delta)


func _on_died() -> void:
    velocity = Vector2.ZERO
    set_physics_process(false)
