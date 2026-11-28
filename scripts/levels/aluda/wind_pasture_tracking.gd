class_name WindPastureTracking
extends RefCounted
## Optional, physical-sign tracking puzzle on the way to Arkhoti.
## No forced movement, morality choices, or saved progression state.

signal clue_found(clue_id: StringName)
signal ridge_trail_confirmed

const CLUE_IDS := [&"hoofprints", &"scrape", &"grass"]

var clues: Dictionary = {}
var gully_inspected: bool = false
var wrong_turns: int = 0
var route_confirmed: bool = false


func examine_clue(clue_id: StringName) -> Dictionary:
	if clue_id not in CLUE_IDS:
		return {}
	var first_time: bool = not clues.has(clue_id)
	if first_time:
		clues[clue_id] = true
		clue_found.emit(clue_id)
	match clue_id:
		&"hoofprints":
			if first_time:
				return {
					"speaker": "Aluda",
					"text": "A nick in the outer horseshoe repeats in the mud. The stolen horses climbed this slope together."
				}
			return {
				"speaker": "The trail",
				"text": "The same damaged horseshoe left a deep print. It points uphill, away from the fold."
			}
		&"scrape":
			if first_time:
				return {
					"speaker": "Aluda",
					"text": "Fresh iron on the slate. One horse slipped while scrambling upward. The broken edge has not yet gathered dust."
				}
			return {
				"speaker": "The trail",
				"text": "An iron scrape crosses the uphill face of the stone. The raiders did not descend here."
			}
		&"grass":
			if first_time:
				return {
					"speaker": "Aluda",
					"text": "The stalks have been pressed flat, but the torn tips point toward the upper ridge. The horses pressed on into the wind."
				}
			return {
				"speaker": "The trail",
				"text": "Flattened grass and bruised stems confirm the movement uphill, toward the crags."
			}
	return {}


func examine_route(route_id: StringName) -> Dictionary:
	match route_id:
		&"gully":
			if not gully_inspected:
				gully_inspected = true
				wrong_turns += 1
				return {
					"speaker": "Aluda",
					"text": "The sheltered gully is a tempting shortcut, but its shallow marks belong to goats. The horses kept to harder ground."
				}
			return {
				"speaker": "The trail",
				"text": "Goat tracks vanish into the sheltered gully. Sanata's river detour lies farther on, but this is not the raiders' main trail."
			}
		&"ridge":
			if route_confirmed:
				return {
					"speaker": "The trail",
					"text": "The uphill route is clear now: scuffed slate, torn grass and the same horseshoe mark."
				}
			if not clues.has(&"hoofprints") or not clues.has(&"grass"):
				return {
					"speaker": "Aluda",
					"text": "The ridge looks passable, but I cannot yet tell which way the stolen horses went. I should read their prints and the bent grass."
				}
			route_confirmed = true
			ridge_trail_confirmed.emit()
			return {
				"speaker": "Aluda",
				"text": "The marks agree. The raiders took the windward ridge toward Arkhoti. I can approach the crags before they are ready."
			}
	return {}


func clue_count() -> int:
	return clues.size()


func approach_bonus_seconds() -> float:
	# A small tactical reward for reading the ground; existing combat is unchanged.
	return 1.5 if route_confirmed else 0.0
