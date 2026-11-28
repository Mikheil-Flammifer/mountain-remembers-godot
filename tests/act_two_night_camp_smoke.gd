extends SceneTree
## Act II's first playable scene preserves the Act I choice; the dream never
## commits a new choice without an explicit E interaction.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed: PackedScene = load("res://scenes/levels/aluda/act_two/night_camp.tscn")
	assert(packed != null)
	var had_choice: bool = has_meta("aluda_act_one_hand_choice")
	var old_choice = get_meta("aluda_act_one_hand_choice") if had_choice else null
	var had_dream: bool = has_meta("aluda_act_two_dream_choice")
	var old_dream = get_meta("aluda_act_two_dream_choice") if had_dream else null

	for choice in [1, 2]:
		set_meta("aluda_act_one_hand_choice", choice)
		var scene: Node2D = packed.instantiate()
		root.add_child(scene)
		await process_frame
		scene.player.set_physics_process(false)
		assert(scene.hand_choice == choice)
		assert(scene.stage == scene.Stage.ARRIVAL)
		assert(scene.dream_choice == scene.DreamChoice.UNDECIDED)

		scene.player.position = Vector2(540, 440)
		scene._interact()
		assert(scene.stage == scene.Stage.WATCH)
		scene._interact()
		assert(scene.stage == scene.Stage.DREAM)
		assert(scene.dream_choice == scene.DreamChoice.UNDECIDED)
		assert(scene.get_node("NightArt").get("dream_mode"))

		# The deliberate lower/strike action is determined by the chosen marker.
		scene.player.position = Vector2(850 if choice == 1 else 1220, 440)
		scene._interact()
		assert(scene.stage == scene.Stage.AWAKENED)
		assert(scene.dream_choice == (scene.DreamChoice.LOWER_DAGGER if choice == 1 else scene.DreamChoice.STRIKE))
		assert(not scene.get_node("NightArt").get("dream_mode"))
		assert(get_meta("aluda_act_two_dream_choice") == int(scene.dream_choice))
		assert(scene.dialogue_panel != null)
		scene.queue_free()
		await process_frame

	if had_choice:
		set_meta("aluda_act_one_hand_choice", old_choice)
	else:
		remove_meta("aluda_act_one_hand_choice")
	if had_dream:
		set_meta("aluda_act_two_dream_choice", old_dream)
	else:
		remove_meta("aluda_act_two_dream_choice")
	print("PASS: Act II night camp, inherited choice and both explicit dream outcomes.")
	quit(0)
