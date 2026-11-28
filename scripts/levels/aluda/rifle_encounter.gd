class_name RifleEncounter
extends Node
## One-shot rifle encounter. Signals let the level present the outcome.

signal updated(text: String)
signal defeated
signal player_defeated

const RELOAD_STEPS := ["Powder", "Bullet", "Ram", "Prime"]
const ENEMY_FIRE_INTERVAL := 4.0

var loaded := true
var reload_step := 0
var enemy_health := 1
var player_health := 2
var enemy_timer := ENEMY_FIRE_INTERVAL
var active := false


func start() -> void:
	active = true
	updated.emit("Mutsal's brother takes cover. F: fire. R: reload in four steps. Stand behind the low rock for cover.")


func fire(can_hit: bool) -> bool:
	if not active or not loaded:
		return false
	loaded = false
	if can_hit:
		enemy_health = 0
		active = false
		updated.emit("The brother falls. Mutsal is somewhere ahead among the rocks.")
		defeated.emit()
	else:
		updated.emit("Shot missed. Press R for powder, bullet, ram and prime.")
	return true


func reload_next() -> bool:
	if not active or loaded:
		return false
	var step: String = RELOAD_STEPS[reload_step]
	reload_step += 1
	if reload_step == RELOAD_STEPS.size():
		loaded = true
		reload_step = 0
		updated.emit("Rifle primed. F to fire.")
	else:
		updated.emit(step + " complete. R: " + RELOAD_STEPS[reload_step] + ".")
	return true


func tick(delta: float, in_cover: bool) -> void:
	if not active:
		return
	enemy_timer -= delta
	if enemy_timer > 0.0:
		return
	enemy_timer = ENEMY_FIRE_INTERVAL
	if in_cover:
		updated.emit("A shot strikes the rock. The raider reloads.")
	else:
		player_health -= 1
		if player_health <= 0:
			active = false
			updated.emit("Aluda is hit. Press R to retry the encounter.")
			player_defeated.emit()
		else:
			updated.emit("Aluda is wounded. Find cover before the next shot.")
