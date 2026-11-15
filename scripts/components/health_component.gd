
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal max_health_increased(new_maximum: int)
signal died

@export_group("Health")
@export var max_health: int = 100
@export var invulnerability_duration: float = 0.8

var current_health: int = 0
var is_dead: bool = false
var _invulnerability_timer: float = 0.0


func _ready() -> void:
	max_health = maxi(max_health, 1)
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	_invulnerability_timer = maxf(
		_invulnerability_timer - delta,
		0.0
	)


func take_damage(amount: int) -> bool:
	if is_dead or _invulnerability_timer > 0.0:
		return false

	if amount <= 0:
		return false

	current_health = maxi(current_health - amount, 0)
	_invulnerability_timer = invulnerability_duration

	damaged.emit(amount)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		is_dead = true
		died.emit()

	return true


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	var previous_health: int = current_health

	current_health = mini(
		current_health + amount,
		max_health
	)

	var actual_healing: int = current_health - previous_health

	if actual_healing > 0:
		healed.emit(actual_healing)
		health_changed.emit(current_health, max_health)


func increase_max_health(
	amount: int,
	heal_extra: bool = true
) -> void:
	if amount <= 0:
		return

	max_health += amount

	if heal_extra and not is_dead:
		current_health += amount

	max_health_increased.emit(max_health)
	health_changed.emit(current_health, max_health)


func restore_full_health() -> void:
	if is_dead:
		return

	current_health = max_health
	health_changed.emit(current_health, max_health)


func is_invulnerable() -> bool:
	return _invulnerability_timer > 0.0


func get_health() -> int:
	return current_health
