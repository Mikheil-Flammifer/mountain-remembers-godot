extends Node
## Add as an Autoload singleton named WorldState in Project Settings > Globals > Autoload.
## Persistent map progression. Saved separately from other gameplay state.

signal location_discovered(location_id: String)
signal current_location_changed(location_id: String)

const WorldLocations = preload("res://scripts/world/world_locations.gd")
const SAVE_PATH: String = "user://world_map_state.json"
const SAVE_VERSION: int = 1
const STARTING_LOCATION: String = "mtskheta"

var current_location_id: String = STARTING_LOCATION
var _discovered: Dictionary = {}


func _ready() -> void:
	_reset_defaults()
	load_state()


func _reset_defaults() -> void:
	_discovered.clear()
	for location in WorldLocations.LOCATIONS:
		if bool(location["known"]):
			_discovered[String(location["id"])] = true
	current_location_id = STARTING_LOCATION


func has_location(location_id: String) -> bool:
	for location in WorldLocations.LOCATIONS:
		if String(location["id"]) == location_id:
			return true
	return false


func is_discovered(location_id: String) -> bool:
	return bool(_discovered.get(location_id, false))


func discover_location(location_id: String) -> void:
	if not has_location(location_id):
		push_warning("[WorldState] Unknown location: " + location_id)
		return
	if is_discovered(location_id):
		return
	_discovered[location_id] = true
	save_state()
	location_discovered.emit(location_id)


func enter_location(location_id: String) -> void:
	if not has_location(location_id):
		push_warning("[WorldState] Unknown location: " + location_id)
		return
	if current_location_id != location_id:
		current_location_id = location_id
		save_state()
		current_location_changed.emit(location_id)
	discover_location(location_id)


func save_state() -> void:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"current_location_id": current_location_id,
		"discovered": _discovered.duplicate()
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[WorldState] Cannot write save: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[WorldState] Cannot open save: " + str(FileAccess.get_open_error()))
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("[WorldState] Invalid save; keeping starting locations")
		return
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != SAVE_VERSION:
		push_warning("[WorldState] Unsupported save version")
		return
	var saved_discovered: Variant = data.get("discovered", {})
	if saved_discovered is Dictionary:
		for location in WorldLocations.LOCATIONS:
			var location_id: String = String(location["id"])
			if bool(saved_discovered.get(location_id, false)):
				_discovered[location_id] = true
	var saved_location: String = String(data.get("current_location_id", STARTING_LOCATION))
	if has_location(saved_location):
		current_location_id = saved_location
