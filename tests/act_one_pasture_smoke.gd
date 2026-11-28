extends SceneTree
## Optional evidence creates a tactical reward without blocking the Arkhoti story.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var packed: PackedScene = load("res://scenes/levels/aluda/act_one/tracking.tscn")
	assert(packed != null)
	var scene: Node2D = packed.instantiate()
	root.add_child(scene)
	await process_frame

	var pasture := scene.get_node_or_null("Subareas/WindPasture")
	assert(pasture != null)
	assert(pasture.has_node("TrailSigns"))
	var tracking: WindPastureTracking = scene.wind_tracking
	assert(tracking != null)
	assert(tracking.clue_count() == 0)
	assert(tracking.approach_bonus_seconds() == 0.0)
	var player: CharacterBody2D = scene.player
	player.set_physics_process(false)
	var talk := InputEventAction.new()
	talk.action = &"talk"
	talk.pressed = true

	# Optional tracking is unavailable until the messenger opens the investigation.
	player.position = Vector2(900, 440)
	scene._unhandled_input(talk)
	assert(tracking.clue_count() == 0)
	player.position = Vector2(160, 440)
	scene._unhandled_input(talk)
	assert(scene.story.phase == scene.Story.Phase.TRACKING)

	# Guessing the ridge without reading the ground gives guidance, not a penalty.
	player.position = Vector2(1160, 440)
	scene._unhandled_input(talk)
	assert(not tracking.route_confirmed)
	assert(scene.dialogue_panel.current_text.contains("prints"))

	# Read signs using the existing E-key interaction; the old story IDs survive.
	for position_x in [750, 900, 1060]:
		player.position = Vector2(position_x, 440)
		scene._unhandled_input(talk)
	assert(tracking.clue_count() == 3)
	assert(scene.story.trail_clues.has(&"hoofprints"))
	assert(scene.story.trail_clues.has(&"grass"))
	assert(scene.story.trail_clues.size() == 2)

	# A false branch is harmless and only counted on first inspection.
	player.position = Vector2(1220, 440)
	scene._unhandled_input(talk)
	scene._unhandled_input(talk)
	assert(tracking.wrong_turns == 1)
	assert(not tracking.route_confirmed)

	# A correct reading produces the optional approach advantage.
	player.position = Vector2(1160, 440)
	scene._unhandled_input(talk)
	assert(tracking.route_confirmed)
	assert(tracking.approach_bonus_seconds() == 1.5)
	scene._update_subarea()
	scene._process(0.016)
	assert(scene.current_subarea == 1)
	assert(scene.trail_status.text.contains("PASTURE  3 / 3"))
	assert(scene.trail_status.text.contains("RIDGE FOUND"))

	# Sanata remains optional; following the crags starts the unchanged fight.
	player.position = Vector2(2400, 440)
	scene._unhandled_input(talk)
	assert(scene.story.phase == scene.Story.Phase.BROTHER_FIGHT)
	assert(scene.rifle.active)
	assert(is_equal_approx(scene.rifle.enemy_timer, scene.rifle.ENEMY_FIRE_INTERVAL + 1.5))

	scene.queue_free()
	await process_frame

	# A second run can skip all pasture signs and still reach the same encounter.
	var skipped: Node2D = packed.instantiate()
	root.add_child(skipped)
	await process_frame
	skipped.player.set_physics_process(false)
	skipped.player.position = Vector2(160, 440)
	skipped._unhandled_input(talk)
	skipped.player.position = Vector2(2400, 440)
	skipped._unhandled_input(talk)
	assert(skipped.story.phase == skipped.Story.Phase.BROTHER_FIGHT)
	assert(skipped.rifle.enemy_timer == skipped.rifle.ENEMY_FIRE_INTERVAL)
	skipped.queue_free()
	await process_frame
	print("PASS: pasture tracking, route judgment, optional bonus and skip path.")
	quit(0)
