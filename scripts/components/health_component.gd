
class_name HealthComponent
extends Node

signal health_changed(
	current_health: int,
	max_health: int
)

signal died

@export var max_health: int = 5

var current_health: int = 0


func _ready() -> void:
	max_health = maxi(max_health, 1)
	current_health = max_health


func take_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health = maxi(
		current_health - amount,
		0
	)

	health_changed.emit(
		current_health,
		max_health
	)

	if current_health == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health = mini(
		current_health + amount,
		max_health
	)

	health_changed.emit(
		current_health,
		max_health
	)


func is_alive() -> bool:
	return current_health > 0
