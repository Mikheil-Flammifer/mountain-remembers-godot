extends Node
## Reusable quest/journal state. A single instance is owned by the level's Story node.
## Saving is independent from WorldState and never overwrites map discoveries.

signal changed

const SAVE_PATH: String = "user://quest_journal_v1.json"
const QUEST_ID: String = "the_road_north"
const MAX_STAGE: int = 3

var stage: int = 0
var entries: Array[String] = []


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	stage = 0
	entries.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		changed.emit()
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[QuestJournal] Could not open save file")
		changed.emit()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[QuestJournal] Invalid save format; starting new journal")
		changed.emit()
		return
	var data: Dictionary = parsed as Dictionary
	stage = clampi(int(data.get("stage", 0)), 0, MAX_STAGE)
	var raw_entries: Variant = data.get("entries", [])
	if typeof(raw_entries) == TYPE_ARRAY:
		for value: Variant in raw_entries:
			if typeof(value) == TYPE_STRING:
				entries.append(value)
	changed.emit()


func complete_step(completed_stage: int, journal_entry: String) -> void:
	# Strict ordering prevents talking to the third NPC first to skip steps.
	if completed_stage != stage + 1 or completed_stage > MAX_STAGE:
		return
	stage = completed_stage
	if not entries.has(journal_entry):
		entries.append(journal_entry)
	save_progress()
	changed.emit()
	print("[QuestJournal] Completed stage %d: %s" % [stage, journal_entry])


func save_progress() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[QuestJournal] Save failed: " + str(FileAccess.get_open_error()))
		return
	var data: Dictionary = {
		"version": 1,
		"quest_id": QUEST_ID,
		"stage": stage,
		"entries": entries,
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()


func objective_text() -> String:
	match stage:
		0: return "Speak with the Mtskheta Elder"
		1: return "Find the Pilgrim along the road"
		2: return "Speak with the Highland Traveler"
		_: return "Follow the Aragvi valley (next chapter)"
