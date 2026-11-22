class_name StaminaComponent
extends Node

signal stamina_changed(current: float, maximum: float)

@export_group("Energy")
@export var max_stamina: float = 100.0
@export var regeneration_per_second: float = 30.0
@export var regeneration_delay: float = 0.52
@export var sword_cost: float = 11.0
@export var jump_cost: float = 9.0
@export var second_jump_cost: float = 18.0
@export var dash_cost: float = 16.0
@export var sprint_per_second: float = 13.0

var current_stamina: float = 100.0
var _delay: float = 0.0


func _ready() -> void:
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)


func _physics_process(delta: float) -> void:
	if _delay > 0.0:
		_delay = maxf(0.0, _delay - delta)
		return

	if current_stamina < max_stamina:
		current_stamina = minf(
			max_stamina,
			current_stamina + regeneration_per_second * delta
		)
		stamina_changed.emit(current_stamina, max_stamina)


func spend(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if current_stamina + 0.001 < amount:
		return false

	current_stamina = maxf(0.0, current_stamina - amount)
	_delay = regeneration_delay
	stamina_changed.emit(current_stamina, max_stamina)
	return true


## Shield blocks always consume whatever energy remains.
## Returns true only when the full guard cost was available.
func drain_for_guard(amount: float) -> bool:
	if amount <= 0.0:
		return true

	var enough: bool = current_stamina + 0.001 >= amount
	current_stamina = maxf(0.0, current_stamina - amount)
	_delay = regeneration_delay
	stamina_changed.emit(current_stamina, max_stamina)
	return enough


func restore_full() -> void:
	current_stamina = max_stamina
	_delay = 0.0
	stamina_changed.emit(current_stamina, max_stamina)


func delay_regeneration(extra_delay: float) -> void:
	_delay = maxf(_delay, extra_delay)
