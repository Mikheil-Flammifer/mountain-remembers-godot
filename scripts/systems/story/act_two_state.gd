class_name ActTwoState
extends RefCounted
## Authoritative Act II sequence: night camp, watch, dream, dream duel, dagger.
## Completely separate from ActOneState. It only receives the finished Act I
## hand choice as a plain value, and refuses to start without one.

signal phase_changed(phase: Phase)
signal dream_decided(choice: DreamChoice)

enum Phase { LOCKED, ARRIVAL, FIRE_TENDED, WEAPON_CHECKED, WATCH_KEPT, DREAM_GATHERING, DREAM_DUEL, DREAM_DAGGER, AWAKENED, COMPLETE }
enum DreamChoice { UNDECIDED, LOWER_DAGGER, STRIKE }

## Same numeric values as ActOneState.HandChoice, kept local so the acts stay decoupled.
const HAND_SPARE := 1
const HAND_CUT := 2
const DUEL_START_ROUNDS := 3
const DUEL_MAX_ROUNDS := 6

var phase: Phase = Phase.LOCKED
var hand_choice: int = 0
var dream_choice: DreamChoice = DreamChoice.UNDECIDED
var duel_rounds_remaining: int = DUEL_START_ROUNDS
var duel_strikes: int = 0
var duel_parries: int = 0
var feast_witnessed: bool = false
var reflected: bool = false


## Act II can begin only from a completed Act I (a deliberate hand choice).
func begin(act_one_hand_choice: int, act_one_complete: bool) -> bool:
	if phase != Phase.LOCKED or not act_one_complete or act_one_hand_choice not in [HAND_SPARE, HAND_CUT]:
		return false
	hand_choice = act_one_hand_choice
	_set_phase(Phase.ARRIVAL)
	return true


func tend_fire() -> bool:
	return _advance(Phase.ARRIVAL, Phase.FIRE_TENDED)


func check_weapon() -> bool:
	return _advance(Phase.FIRE_TENDED, Phase.WEAPON_CHECKED)


func keep_watch() -> bool:
	return _advance(Phase.WEAPON_CHECKED, Phase.WATCH_KEPT)


func sleep() -> bool:
	return _advance(Phase.WATCH_KEPT, Phase.DREAM_GATHERING)


func witness_feast() -> bool:
	if phase != Phase.DREAM_GATHERING:
		return false
	feast_witnessed = true
	return true


func face_mutsal() -> bool:
	if not feast_witnessed:
		return false
	return _advance(Phase.DREAM_GATHERING, Phase.DREAM_DUEL)


## A guarded exchange. Enough of them end the mirror duel.
func parry() -> bool:
	if phase != Phase.DREAM_DUEL:
		return false
	duel_parries += 1
	duel_rounds_remaining -= 1
	if duel_rounds_remaining <= 0:
		duel_rounds_remaining = 0
		_set_phase(Phase.DREAM_DAGGER)
	return true


## Attacking the shade only brings more rounds. It never records the decision.
func strike_in_duel() -> bool:
	if phase != Phase.DREAM_DUEL:
		return false
	duel_strikes += 1
	duel_rounds_remaining = mini(duel_rounds_remaining + 1, DUEL_MAX_ROUNDS)
	return true


## The only place the dream decision is recorded.
func decide_dream(choice: DreamChoice) -> bool:
	if phase != Phase.DREAM_DAGGER or choice not in [DreamChoice.LOWER_DAGGER, DreamChoice.STRIKE]:
		return false
	dream_choice = choice
	dream_decided.emit(choice)
	_set_phase(Phase.AWAKENED)
	return true


func reflect() -> bool:
	if phase != Phase.AWAKENED:
		return false
	reflected = true
	return true


func break_camp() -> bool:
	if not reflected:
		return false
	return _advance(Phase.AWAKENED, Phase.COMPLETE)


func _advance(from: Phase, to: Phase) -> bool:
	if phase != from:
		return false
	_set_phase(to)
	return true


func _set_phase(next: Phase) -> void:
	phase = next
	phase_changed.emit(phase)
