extends SceneTree

## Run: godot --headless --path . --script res://tests/mtskheta_travel_routes.gd
## Verify that all Mtskheta exits lead to a matching spawn and allow return travel.
const AREA_DIR := "res://scenes/levels/mtskheta/"
const AREAS := [
    "mtskheta.tscn", "market.tscn", "streets.tscn",
    "cathedral_precinct.tscn", "terraces.tscn", "north_road.tscn",
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
        var ids: Dictionary = {}
        var connections: Array[Dictionary] = []
        for child: Node in root.get_children():
            if child is Marker2D and child.get_script() != null and child.get("spawn_id") != null:
                var spawn: String = str(child.get("spawn_id"))
                if ids.has(spawn):
                    errors.append("Duplicate spawn " + spawn + " in " + name)
                ids[spawn] = true
            if child is Area2D and child.get_script() != null and child.get("target_scene") != null:
                connections.append({
                    "target": str(child.get("target_scene")).get_file(),
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

    var visited: Dictionary = {"mtskheta.tscn": true}
    var queue: Array[String] = ["mtskheta.tscn"]
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
        print("PASS: All six Mtskheta scenes have connected return routes.")
        quit(0)
    else:
        for message: String in errors:
            push_error(message)
        quit(1)