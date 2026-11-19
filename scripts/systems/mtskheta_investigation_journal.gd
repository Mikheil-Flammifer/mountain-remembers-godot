class_name MtskhetaInvestigationJournal
extends "res://scripts/systems/quest_journal.gd"

## Shares the existing user://quest_journal_v1.json save with the original
## Mtskheta story and the cathedral. Does not change the main quest stage.


func has_clue(entry: String) -> bool:
    return entries.has(entry)


func record_clue(entry: String) -> bool:
    if entry.is_empty() or entries.has(entry):
        return false
    entries.append(entry)
    save_progress()
    changed.emit()
    return true
