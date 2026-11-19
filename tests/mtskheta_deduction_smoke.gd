extends SceneTree

func _initialize() -> void:
    call_deferred("_check")


func _check() -> void:
    var entries: Array[String] = [
        MtskhetaInvestigationData.MARKET_CLUE,
        MtskhetaInvestigationData.STREETS_CLUE
    ]
    if not MtskhetaInvestigationData.deduction_available(entries):
        _fail("Two clues should enable deduction")
        return
    if MtskhetaInvestigationData.deduction_available([MtskhetaInvestigationData.MARKET_CLUE]):
        _fail("One clue must not enable deduction")
        return
    if MtskhetaInvestigationData.DEDUCTION_CLUE.is_empty():
        _fail("Deduction journal text is empty")
        return
    if MtskhetaInvestigationData.deduction_feedback(2).is_empty():
        _fail("No feedback for correct deduction")
        return
    print("PASS: Deduction requires both clues and provides an evidence-based conclusion.")
    quit(0)


func _fail(message: String) -> void:
    push_error(message)
    quit(1)
