extends SceneTree

## Run: godot --headless --path . --script res://tests/mtskheta_investigation_smoke.gd


func _initialize() -> void:
    call_deferred("_check")


func _check() -> void:
    var cases: Array[Dictionary] = [
        {"scene": "res://scenes/levels/mtskheta/market.tscn", "npc": "AragviMerchant"},
        {"scene": "res://scenes/levels/mtskheta/streets.tscn", "npc": "StreetPilgrim"},
    ]
    for test_case: Dictionary in cases:
        var packed: PackedScene = load(str(test_case["scene"])) as PackedScene
        if packed == null:
            _fail("Could not load scene: " + str(test_case["scene"]))
            return
        var root: Node = packed.instantiate()
        if root.get_node_or_null("InvestigationController") == null:
            root.free()
            _fail("Missing InvestigationController: " + str(test_case["scene"]))
            return
        if root.get_node_or_null(str(test_case["npc"])) == null:
            root.free()
            _fail("Missing NPC: " + str(test_case["npc"]))
            return
        root.free()

    var market_dialogue: Dictionary = MtskhetaInvestigationData.conversation(
        "aragvi_merchant", false, false
    )
    var pilgrim_dialogue: Dictionary = MtskhetaInvestigationData.conversation(
        "street_pilgrim", true, false
    )
    if str(market_dialogue.get("clue", "")).is_empty():
        _fail("Merchant should award a clue")
        return
    if str(pilgrim_dialogue.get("clue", "")).is_empty():
        _fail("Pilgrim should award a clue after merchant")
        return

    print("PASS: Market and Streets NPC investigation scenes are connected.")
    quit(0)


func _fail(message: String) -> void:
    push_error(message)
    quit(1)
