extends SceneTree

func _initialize() -> void:
	_check.call_deferred()

func _check() -> void:
	var progress = load("res://scripts/systems/story/act_progress.gd")
	assert(progress.ACT_SCENES[1].ends_with("shatili_castle_feast.tscn"))
	var feast = load(progress.ACT_SCENES[1]).instantiate()
	root.add_child(feast)
	await process_frame
	assert(feast.phase == feast.Phase.FEAST)
	assert(not feast.get_node("Messenger").visible)
	feast._messenger_arrives()
	assert(feast.phase == feast.Phase.REPORT)
	assert(feast.get_node("Messenger").visible)
	feast._show_courtyard()
	assert(feast.phase == feast.Phase.HORSE)
	assert(not feast.get_node("FeastTable").visible)
	feast.queue_free()
	await process_frame
	set_meta("act_one_feast_report", true)
	var tracking = load("res://scenes/levels/aluda/act_one/tracking.tscn").instantiate()
	root.add_child(tracking)
	await process_frame
	assert(tracking.story.phase == tracking.Story.Phase.TRACKING)
	assert(not has_meta("act_one_feast_report"))
	tracking.queue_free()
	await process_frame
	print("PASS: feast, messenger, horse setup and pursuit handoff.")
	quit()
