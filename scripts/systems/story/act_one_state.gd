class_name ActOneState
extends RefCounted
## Authoritative Act 1 sequence. Scenes call these methods after actions complete.

signal phase_changed(phase: Phase)
signal hand_decided(choice: HandChoice)

enum Phase { RAID_REPORT, TRACKING, BROTHER_FIGHT, MUTSAL_RIFLE, MUTSAL_COVER, MUTSAL_FINAL, HAND_DECISION, COMPLETE }
enum HandChoice { UNDECIDED, SPARE, CUT }

var phase: Phase = Phase.RAID_REPORT
var hand_choice: HandChoice = HandChoice.UNDECIDED
var visited_river: bool = false
var met_sanata: bool = false
var trail_clues: Dictionary = {}
var powder_horn_destroyed: bool = false
var mutsal_fired_final_shot: bool = false
var mutsal_threw_rifle: bool = false
var brother_arm_taken: bool = false
var mutsal_weapons_left: bool = false
var body_covered: bool = false


func receive_raid_report() -> bool:
	if phase != Phase.RAID_REPORT:
		return false
	_set_phase(Phase.TRACKING)
	return true


func inspect_trail(clue_id: StringName) -> bool:
	if phase != Phase.TRACKING or clue_id not in [&"hoofprints", &"grass", &"stones", &"birds", &"dogs"]:
		return false
	trail_clues[clue_id] = true
	return true


func visit_river() -> bool:
	if phase != Phase.TRACKING:
		return false
	visited_river = true
	return true


func meet_sanata() -> bool:
	if phase != Phase.TRACKING or not visited_river:
		return false
	met_sanata = true
	return true


func reach_crags() -> bool:
	if phase != Phase.TRACKING:
		return false
	_set_phase(Phase.BROTHER_FIGHT)
	return true


func defeat_brother() -> bool:
	if phase != Phase.BROTHER_FIGHT:
		return false
	_set_phase(Phase.MUTSAL_RIFLE)
	return true


func break_cover() -> bool:
	if phase != Phase.MUTSAL_RIFLE:
		return false
	powder_horn_destroyed = true
	_set_phase(Phase.MUTSAL_COVER)
	return true


func wound_mutsal() -> bool:
	if phase != Phase.MUTSAL_COVER:
		return false
	_set_phase(Phase.MUTSAL_FINAL)
	return true


func record_final_shot() -> bool:
	if phase != Phase.MUTSAL_FINAL or mutsal_fired_final_shot:
		return false
	mutsal_fired_final_shot = true
	return true


func record_thrown_rifle() -> bool:
	if phase != Phase.MUTSAL_FINAL or not mutsal_fired_final_shot or mutsal_threw_rifle:
		return false
	mutsal_threw_rifle = true
	_set_phase(Phase.HAND_DECISION)
	return true


func decide_hand(choice: HandChoice) -> bool:
	if phase != Phase.HAND_DECISION or hand_choice != HandChoice.UNDECIDED or choice not in [HandChoice.SPARE, HandChoice.CUT]:
		return false
	hand_choice = choice
	hand_decided.emit(choice)
	return true


func finish_aftermath() -> bool:
	if phase != Phase.HAND_DECISION or hand_choice == HandChoice.UNDECIDED:
		return false
	brother_arm_taken = true
	mutsal_weapons_left = true
	body_covered = true
	_set_phase(Phase.COMPLETE)
	return true


func _set_phase(next: Phase) -> void:
	phase = next
	phase_changed.emit(phase)
