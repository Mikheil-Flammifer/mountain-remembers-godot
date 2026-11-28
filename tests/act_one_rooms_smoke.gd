extends SceneTree

func _initialize() -> void:
	_check.call_deferred()

func _check() -> void:
	var scene = load("res://scenes/levels/aluda/act_one/tracking.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.story.receive_raid_report()
	scene.story.inspect_trail(&"dogs")
	var player = scene.player
	player.position = Vector2(450, 440)
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
	Input.action_release("move_right")
	assert(player.position.x < 200, "Walking onto unstable ground returns the player to safety")
	assert(scene.story.trail_clues.has(&"dogs"))
	scene.dialogue_panel.close()
	scene._hazard_cooldown = 0.0
	player.position = Vector2(450, 440)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	Input.action_press("move_right")
	Input.action_press("jump")
	for i in 35:
		await physics_frame
	Input.action_release("jump")
	Input.action_release("move_right")
	assert(player.position.x > 550, "Jumping clears the unstable ground")
	player.position = Vector2(655, 440)
	scene._detect_room_exit()
	assert(scene._room_transitioning)
	await create_timer(0.6).timeout
	assert(scene.current_subarea == 1 and not scene._room_transitioning)
	assert(scene.story.trail_clues.has(&"dogs"))
	player.position = Vector2(645, 440)
	scene._detect_room_exit()
	await create_timer(0.6).timeout
	assert(scene.current_subarea == 0)
	player.position = Vector2(2870, 440)
	scene.current_subarea = 3
	scene._detect_room_exit()
	assert(not scene._room_transitioning and player.position.x < 2860)
	scene.story.reach_crags()
	scene.story.defeat_brother()
	player.position.x = 2870
	scene._detect_room_exit()
	await create_timer(0.6).timeout
	assert(scene.current_subarea == 4)
	assert(scene.story.phase == scene.Story.Phase.MUTSAL_RIFLE)
	scene._on_hazard_touched(player)
	assert(player.position.x == 2925)
	assert(scene.story.trail_clues.has(&"dogs"))
	scene.queue_free()
	await process_frame
	print("PASS: room transitions, backtracking, combat gate and hazard recovery preserve story state.")
	quit()
