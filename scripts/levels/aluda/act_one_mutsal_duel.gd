class_name ActOneMutsalDuel
extends Node
## Playable, staged rifle duel. ActOneState owns the canonical story phases.
## Finishing the shots triggers a scripted final exchange, never a moral choice.

signal updated(speaker: String, line: String)
signal final_exchange_complete
signal player_defeated

const RELOAD_STEPS := ["Powder", "Ball", "Ram", "Prime"]
const FIRE_INTERVAL: float = 5.0

var story: ActOneState
var active: bool = false
var loaded: bool = true
var reload_step: int = 0
var health: int = 2
var enemy_timer: float = FIRE_INTERVAL
var final_timer: float = -1.0
var _final_shot_recorded: bool = false


func begin(state: ActOneState) -> bool:
	if state.phase != ActOneState.Phase.MUTSAL_RIFLE:
		return false
	story = state
	active = true
	loaded = true
	reload_step = 0
	health = 2
	enemy_timer = FIRE_INTERVAL
	final_timer = -1.0
	_final_shot_recorded = false
	updated.emit("Mutsal", "You have slain my brother. Face me among these rocks.")
	return true


func attempt_shot(in_range: bool) -> bool:
	if not active or not loaded or story == null:
		return false
	loaded = false
	if not in_range:
		updated.emit("The crags", "Your ball strikes slate. R to reload behind cover.")
		return true
	if story.phase == ActOneState.Phase.MUTSAL_RIFLE:
		if story.break_cover():
			updated.emit("The crags", "Mutsal breaks from cover. A shot tears your powder horn; a little powder remains. Reload and take your aim.")
	elif story.phase == ActOneState.Phase.MUTSAL_COVER:
		if story.wound_mutsal():
			active = false
			final_timer = 0.0
			updated.emit("Mutsal", "Wounded, he presses mountain grass against the wound. He has not lowered his rifle.")
	return true


func reload_next() -> bool:
	if not active or loaded:
		return false
	var step: String = RELOAD_STEPS[reload_step]
	reload_step += 1
	if reload_step >= RELOAD_STEPS.size():
		reload_step = 0
		loaded = true
		updated.emit("The crags", "Rifle primed. Face Mutsal and press F to fire.")
	else:
		updated.emit("The crags", "%s complete. R to %s." % [step, RELOAD_STEPS[reload_step].to_lower()])
	return true


func retry() -> bool:
	# A retry keeps the canonical story phase: no undone moral choices.
	if story == null or story.phase not in [ActOneState.Phase.MUTSAL_RIFLE, ActOneState.Phase.MUTSAL_COVER]:
		return false
	active = true
	loaded = true
	reload_step = 0
	health = 2
	enemy_timer = FIRE_INTERVAL
	updated.emit("The crags", "Back behind the rock. Listen for his shot and return fire.")
	return true


func tick(delta: float, in_cover: bool) -> void:
	if story == null:
		return
	if story.phase == ActOneState.Phase.MUTSAL_FINAL and final_timer >= 0.0:
		final_timer += maxf(delta, 0.0)
		if final_timer >= 1.5 and not _final_shot_recorded:
			_final_shot_recorded = story.record_final_shot()
			if _final_shot_recorded:
				updated.emit("The crags", "Mutsal fires one last shot. He has barely strength to raise the barrel.")
		if final_timer >= 3.4 and _final_shot_recorded:
			final_timer = -1.0
			if story.record_thrown_rifle():
				updated.emit("Mutsal", "He throws his rifle across the stones. His struggle is over.")
				final_exchange_complete.emit()
		return
	if not active:
		return
	enemy_timer -= maxf(delta, 0.0)
	if enemy_timer > 0.0:
		return
	enemy_timer = FIRE_INTERVAL
	if in_cover:
		updated.emit("The crags", "A ball cracks against your shelter. Mutsal must reload.")
	else:
		health -= 1
		if health <= 0:
			active = false
			updated.emit("The crags", "Aluda falls beneath the fire. Press R to retry this duel.")
			player_defeated.emit()
		else:
			updated.emit("The crags", "Mutsal's shot grazes you. Find the sheltered side of the boulder.")
