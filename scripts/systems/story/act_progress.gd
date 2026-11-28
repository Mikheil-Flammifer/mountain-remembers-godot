class_name ActProgress
extends RefCounted
## Which acts are finished, kept on disk so the act menu remembers them.
## Each act unlocks only after the previous act is complete. Only the values a
## later act needs (Act I hand choice, Act II dream choice) are stored.

const ACT_COUNT := 5
const ACT_TITLES := ["Raid and duel", "Night camp and dream", "Return and council", "The arm", "The shrine feast"]
## Scenes that exist. Acts without a scene show as "not built yet".
const ACT_SCENES := {
	1: "res://scenes/levels/aluda/prologue/shatili_castle_feast.tscn",
	2: "res://scenes/levels/aluda/act_two/night_camp.tscn",
}

## Tests point this at a throwaway file so real saves are never touched.
static var save_path: String = "user://act_progress.cfg"


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(save_path)
	return cfg


static func is_complete(act: int) -> bool:
	return bool(_load().get_value("act_%d" % act, "complete", false))


static func is_unlocked(act: int) -> bool:
	if act < 1 or act > ACT_COUNT:
		return false
	return act == 1 or is_complete(act - 1)


static func is_built(act: int) -> bool:
	return ACT_SCENES.has(act)


static func get_value(act: int, key: String, default: Variant = null) -> Variant:
	return _load().get_value("act_%d" % act, key, default)


static func mark_complete(act: int, values: Dictionary = {}) -> void:
	var cfg := _load()
	var section := "act_%d" % act
	cfg.set_value(section, "complete", true)
	for key in values:
		cfg.set_value(section, key, values[key])
	cfg.save(save_path)


static func reset() -> void:
	var cfg := ConfigFile.new()
	cfg.save(save_path)
