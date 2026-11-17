extends SceneTree

## Run: godot --headless --path . --script res://tests/mtskheta_return_safety.gd
## Detect entrances placed on the wrong side of their corresponding exit.
const AREA_DIR: String = "res://scenes/levels/mtskheta/"
const MIN_CLEARANCE: float = 160.0
const CASES: Dictionary = {
	"mtskheta.tscn": [["SpawnFromMarket", "ToMarketDistrict", "left"]],
	"market.tscn": [
		["SpawnFromOldTown", "ToOldTown", "right"],
		["SpawnFromStreets", "ToStreets", "left"],
	],
	"streets.tscn": [
		["SpawnFromMarket", "ToMarket", "right"],
		["SpawnFromTerraces", "ToTerraces", "left"],
	],
	"terraces.tscn": [
		["SpawnFromStreets", "ToStreets", "right"],
		["SpawnFromNorthRoad", "ToNorthRoad", "left"],
	],
	"cathedral_precinct.tscn": [
		["SpawnFromTerraces", "ToTerraces", "left"],
	],
	"north_road.tscn": [["SpawnFromTerraces", "ToTerraces", "right"]],
}


func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	var errors: Array[String] = []
	for filename: String in CASES.keys():
		var packed: PackedScene = load(AREA_DIR + filename) as PackedScene
		if packed == null:
			errors.append("Cannot load " + filename)
			continue
		var root: Node = packed.instantiate()
		for case_data: Array in CASES[filename]:
			var spawn_name: String = str(case_data[0])
			var portal_name: String = str(case_data[1])
			var side: String = str(case_data[2])
			var spawn: Node2D = root.get_node_or_null(spawn_name) as Node2D
			var portal: Node2D = root.get_node_or_null(portal_name) as Node2D
			if spawn == null or portal == null:
				errors.append("Missing " + spawn_name + " or " + portal_name + " in " + filename)
				continue
			var offset: float = spawn.position.x - portal.position.x
			var distance: float = -offset if side == "left" else offset
			if distance < MIN_CLEARANCE:
				errors.append("Unsafe return spawn in %s: %s / %s (clearance %.1f)" % [filename, spawn_name, portal_name, distance])
		root.free()

	if errors.is_empty():
		print("PASS: Every Mtskheta return spawn is safely inside its district.")
		quit(0)
	else:
		for msg: String in errors:
			push_error(msg)
		quit(1)
