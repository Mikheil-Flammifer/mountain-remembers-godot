class_name StaminaComponent
extends Node

signal stamina_changed(current: float, maximum: float)

@export var max_stamina: float = 100.0
@export var regeneration_per_second: float = 24.0
@export var regeneration_delay: float = 0.65
@export var sword_cost: float = 14.0
@export var jump_cost: float = 12.0
@export var second_jump_cost: float = 24.0
@export var sprint_per_second: float = 17.0

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
		current_stamina = minf(max_stamina, current_stamina + regeneration_per_second * delta)
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
