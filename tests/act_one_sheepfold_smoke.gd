extends SceneTree
## Sheepfold investigation is optional, repeatable, and does not change Act 1 plot.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var packed: PackedScene = load("res://scenes/levels/aluda/act_one/tracking.tscn")
	assert(packed != null)
	var scene: Node2D = packed.instantiate()
	root.add_child(scene)
	await process_frame

	var sheepdog := scene.get_node_or_null("Subareas/ShepherdsFold/SilentSheepdog") as SilentSheepdog
	assert(sheepdog != null)
	assert(not sheepdog.calm)
	assert(scene.get_node_or_null("Subareas/ShepherdsFold/RaidEvidenceProps") != null)
	var player: CharacterBody2D = scene.player
	player.set_physics_process(false)
	var talk := InputEventAction.new()
	talk.action = &"talk"
	talk.pressed = true

	# Talking to the messenger is still required before investigating anything.
	player.position = Vector2(295, 440)
	scene._unhandled_input(talk)
	assert(scene.story.phase == scene.Story.Phase.RAID_REPORT)
	assert(scene.fold_investigation.evidence_count() == 0)

	player.position = Vector2(160, 440)
	scene._unhandled_input(talk)
	assert(scene.story.phase == scene.Story.Phase.TRACKING)

	player.position = Vector2(295, 440)
	scene._unhandled_input(talk)
	assert(scene.fold_investigation.inspected.has(&"halter"))
	assert(scene.dialogue_panel.current_text.contains("halter"))
	assert(scene.fold_investigation.evidence_count() == 1)

	player.position = Vector2(430, 440)
	scene._unhandled_input(talk)
	assert(scene.fold_investigation.inspected.has(&"dogs"))
	assert(scene.story.trail_clues.has(&"dogs"))
	assert(not sheepdog.calm)
	scene._unhandled_input(talk)
	assert(scene.fold_investigation.dog_calm)
	assert(sheepdog.calm)
	assert(scene.fold_investigation.evidence_count() == 2)

	player.position = Vector2(570, 440)
	scene._unhandled_input(talk)
	assert(scene.fold_investigation.inspected.has(&"gate"))
	assert(scene.fold_investigation.evidence_count() == 3)
	scene._unhandled_input(talk)
	assert(scene.fold_investigation.evidence_count() == 3)
	scene._process(0.016)
	assert(scene.trail_status.text.contains("3 / 3"))
	assert(scene.story.trail_clues.size() == 1)

	# Investigation never prevents following the trail or entering the crags.
	player.position = Vector2(750, 440)
	scene._unhandled_input(talk)
	assert(scene.story.trail_clues.has(&"hoofprints"))
	player.position = Vector2(2400, 440)
	scene._unhandled_input(talk)
	assert(scene.story.phase == scene.Story.Phase.BROTHER_FIGHT)

	scene.queue_free()
	await process_frame
	print("PASS: sheepfold evidence, dog comfort, non-blocking story and Act 1 travel.")
	quit(0)
