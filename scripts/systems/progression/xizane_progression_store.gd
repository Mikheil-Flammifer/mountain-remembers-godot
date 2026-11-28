class_name XizaneProgressionStore
extends RefCounted
## Keeps progression across player instances and serializes the existing save format.

const META_STONES: String = "xizane_healing_stones"
const META_COLLECTED_STONES: String = "xizane_collected_healing_stones"
const META_SCORE: String = "xizane_score"
const META_UPGRADES: String = "xizane_upgrade_levels"
const META_LOST_SCORE: String = "xizane_lost_score"
const META_LOST_SCENE: String = "xizane_lost_score_scene"
const META_LOST_POSITION: String = "xizane_lost_score_position"
const META_PROGRESS_LOADED: String = "xizane_progression_loaded"
const PROGRESSION_SAVE_PATH: String = "user://xizane_progression.json"

var root: Window


func _init(session_root: Window) -> void:
	root = session_root
	_load_from_disk_once()


func get_stones(capacity: int) -> int:
	return clampi(int(root.get_meta(META_STONES, 1)), 0, capacity)


func get_score() -> int:
	return maxi(0, int(root.get_meta(META_SCORE, 0)))


func get_levels() -> Dictionary:
	var levels := XizaneUpgradeRules.default_levels()
	var saved: Variant = root.get_meta(META_UPGRADES, {})
	if saved is Dictionary:
		for kind: String in levels:
			levels[kind] = XizaneUpgradeRules.clamp_level(int(saved.get(kind, 1)))
	return levels


static func has_collected(session_root: Window, pickup_id: String) -> bool:
	var collected: Dictionary = session_root.get_meta(META_COLLECTED_STONES, {})
	return collected.has(pickup_id)


func mark_collected(pickup_id: String) -> void:
	var collected: Dictionary = root.get_meta(META_COLLECTED_STONES, {})
	collected[pickup_id] = true
	root.set_meta(META_COLLECTED_STONES, collected)


func get_lost_amount() -> int:
	return maxi(0, int(root.get_meta(META_LOST_SCORE, 0)))


func get_lost_scene() -> String:
	return String(root.get_meta(META_LOST_SCENE, ""))


func get_lost_position(fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var position: Variant = root.get_meta(META_LOST_POSITION, fallback)
	return position if position is Vector2 else fallback


func set_lost_score(amount: int, scene_path: String = "", position: Vector2 = Vector2.ZERO) -> void:
	root.set_meta(META_LOST_SCORE, amount)
	root.set_meta(META_LOST_SCENE, scene_path if amount > 0 else "")
	root.set_meta(META_LOST_POSITION, position if amount > 0 else Vector2.ZERO)


func save(score: int, stones: int, levels: Dictionary) -> void:
	root.set_meta(META_SCORE, score)
	root.set_meta(META_STONES, stones)
	root.set_meta(META_UPGRADES, levels.duplicate())
	var lost_position := get_lost_position()
	var data := {
		"score": score,
		"healing_stones": stones,
		"collected_stones": root.get_meta(META_COLLECTED_STONES, {}),
		"upgrades": levels,
		"lost_score": get_lost_amount(),
		"lost_scene": get_lost_scene(),
		"lost_position": [lost_position.x, lost_position.y],
	}
	var file := FileAccess.open(PROGRESSION_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _load_from_disk_once() -> void:
	if bool(root.get_meta(META_PROGRESS_LOADED, false)):
		return
	root.set_meta(META_PROGRESS_LOADED, true)

	if not FileAccess.file_exists(PROGRESSION_SAVE_PATH):
		return
	var file := FileAccess.open(PROGRESSION_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return

	var data: Dictionary = parsed
	root.set_meta(META_SCORE, maxi(0, int(data.get("score", 0))))
	root.set_meta(META_STONES, maxi(0, int(data.get("healing_stones", 1))))
	var saved_collected: Variant = data.get("collected_stones", {})
	if saved_collected is Dictionary:
		root.set_meta(META_COLLECTED_STONES, saved_collected)
	var saved_upgrades: Variant = data.get("upgrades", {})
	if saved_upgrades is Dictionary:
		root.set_meta(META_UPGRADES, saved_upgrades)

	var lost_amount: int = maxi(0, int(data.get("lost_score", 0)))
	root.set_meta(META_LOST_SCORE, lost_amount)
	root.set_meta(META_LOST_SCENE, String(data.get("lost_scene", "")))
	var position_data: Variant = data.get("lost_position", [0.0, 0.0])
	if position_data is Array and position_data.size() >= 2:
		root.set_meta(META_LOST_POSITION, Vector2(float(position_data[0]), float(position_data[1])))
	else:
		root.set_meta(META_LOST_POSITION, Vector2.ZERO)
