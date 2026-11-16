extends "res://scripts/systems/quest_journal.gd"

## Adds cathedral clues to the existing saved quest journal without
## advancing the Elder / Pilgrim / Highland Traveler main quest stages.


func has_clue(entry: String) -> bool:
	return entries.has(entry)


func record_clue(entry: String) -> bool:
	if entry.is_empty() or entries.has(entry):
		return false

	entries.append(entry)
	save_progress()
	changed.emit()
	return true
