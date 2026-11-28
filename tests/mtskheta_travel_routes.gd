extends SceneTree

## Run: godot --headless --path . --script res://tests/mtskheta_travel_routes.gd
## Verify that all Mtskheta exits lead to a matching spawn and allow return travel.
const AREA_DIR := "res://scenes/levels/"
const START_AREA := "mtskheta/market.tscn"
const ZHINVALI_ENTRY := "zhinvali/zhinvali_river_gate.tscn"
const AREAS := [
    "mtskheta/mtskheta.tscn", "mtskheta/market.tscn", "mtskheta/streets.tscn",
    "mtskheta/cathedral_precinct.tscn", "mtskheta/terraces.tscn", "mtskheta/north_road.tscn",
    "jvari/jvari_confluence_trail.tscn", "jvari/jvari_pilgrim_steps.tscn",
    "jvari/jvari_windcut_ravine.tscn", "jvari/jvari_stone_ascent.tscn", "jvari/jvari_monastery.tscn",
    "jvari/jvari_monastery_interior.tscn", "jvari/jvari_pass_wardens.tscn",
    ZHINVALI_ENTRY,
]

func _initialize() -> void:
    call_deferred("_check_routes")

func _check_routes() -> void:
    var spawns: Dictionary = {}
    var exits: Dictionary = {}
    var errors: Array[String] = []
    for name: String in AREAS:
        var scene: PackedScene = load(AREA_DIR + name) as PackedScene
        if scene == null:
            errors.append("Cannot load " + name)
            continue
        var root: Node = scene.instantiate()
        if name.begins_with("jvari/") and not root.has_method("camera_bounds"):
            errors.append("Missing level script in " + name)
        var ids: Dictionary = {}
        var connections: Array[Dictionary] = []
        for child: Node in root.get_children():
            if child is Marker2D and child.get_script() != null and child.get("spawn_id") != null:
                var spawn: String = str(child.get("spawn_id"))
                if ids.has(spawn):
                    errors.append("Duplicate spawn " + spawn + " in " + name)
                ids[spawn] = true
            if child is Area2D and child.get_script() != null and child.get("target_scene") != null:
                var target := String(child.get("target_scene")).trim_prefix(AREA_DIR)
                # Validate both ways across the Jvari boundary. The paths deeper
                # into Zhinvali are outside this test's route graph.
                if name == ZHINVALI_ENTRY and target.begins_with("zhinvali/"):
                    continue
                connections.append({
                    "target": target,
                    "spawn": str(child.get("target_spawn_id"))
                })
        spawns[name] = ids
        exits[name] = connections
        root.free()

    for name: String in exits:
        for portal: Dictionary in exits[name]:
            var destination: String = str(portal["target"])
            var spawn: String = str(portal["spawn"])
            if not spawns.has(destination) or not spawns[destination].has(spawn):
                errors.append("%s -> %s missing spawn %s" % [name, destination, spawn])
            var has_return: bool = false
            for reverse: Dictionary in exits.get(destination, []):
                if str(reverse["target"]) == name:
                    has_return = true
            if not has_return:
                errors.append("%s -> %s has no return portal" % [name, destination])

    var visited: Dictionary = {START_AREA: true}
    var queue: Array[String] = [START_AREA]
    while not queue.is_empty():
        var current: String = queue.pop_front()
        for portal: Dictionary in exits.get(current, []):
            var destination: String = str(portal["target"])
            if not visited.has(destination):
                visited[destination] = true
                queue.append(destination)
    for name: String in AREAS:
        if not visited.has(name):
            errors.append("Unreachable district: " + name)

    if errors.is_empty():
        print("PASS: Mtskheta and Jvari scenes have connected return routes.")
        quit(0)
    else:
        for message: String in errors:
            push_error(message)
        quit(1)