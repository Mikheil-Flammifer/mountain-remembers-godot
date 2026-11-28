extends SceneTree
## Verify seamless Act I travel, canonical Mutsal sequence and Act II handoff.
## Do not actually change scenes inside this smoke test.

const Story = preload("res://scripts/systems/story/act_one_state.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed: PackedScene = load("res://scenes/levels/aluda/act_one/tracking.tscn")
	assert(packed != null)

	for hand_choice: int in [Story.HandChoice.SPARE, Story.HandChoice.CUT]:
		var act_one: Node2D = packed.instantiate()
		root.add_child(act_one)
		await process_frame
		var player: CharacterBody2D = act_one.player
		player.set_physics_process(false)
		assert(not act_one.can_leave_for_act_two())
		assert(act_one.current_subarea == 0)
		assert(act_one.get_node_or_null("Atmosphere") != null)

		# Walk directly over the old four area boundaries.
		player.position = Vector2(750, 440)
		act_one._update_subarea()
		assert(act_one.current_subarea == 1)
		assert(is_equal_approx(act_one.checkpoint_position.x, 690.0))
		player.position = Vector2(1450, 440)
		act_one._update_subarea()
		assert(act_one.current_subarea == 2)
		player.position = Vector2(2220, 440)
		act_one._update_subarea()
		assert(act_one.current_subarea == 3)
		assert(is_equal_approx(act_one.checkpoint_position.x, 1960.0))

		# A fall respawns at the latest in-memory area checkpoint.
		player.position.y = 900.0
		act_one._process(0.016)
		assert(is_equal_approx(player.position.x, 1960.0))
		assert(is_equal_approx(player.position.y, 440.0))

		var talk := InputEventAction.new()
		talk.action = &"talk"
		talk.pressed = true
		player.position = Vector2(160, 440)
		act_one._unhandled_input(talk)
		assert(act_one.story.phase == Story.Phase.TRACKING)
		player.position = Vector2(2400, 440)
		act_one._unhandled_input(talk)
		assert(act_one.story.phase == Story.Phase.BROTHER_FIGHT)
		assert(not act_one.can_leave_for_act_two())

		# First rifle encounter leads to Mutsal, rather than skipping to Act II.
		assert(act_one.rifle.fire(true))
		assert(act_one.story.phase == Story.Phase.MUTSAL_RIFLE)
		assert(act_one.mutsal.visible and act_one.mutsal_duel.active)
		var duel: ActOneMutsalDuel = act_one.mutsal_duel
		assert(duel.attempt_shot(true))
		assert(act_one.story.phase == Story.Phase.MUTSAL_COVER)
		assert(not duel.loaded)
		for i in range(4):
			assert(duel.reload_next())
		assert(duel.loaded)
		assert(duel.attempt_shot(true))
		assert(act_one.story.phase == Story.Phase.MUTSAL_FINAL)
		duel.tick(1.7, true)
		assert(act_one.story.mutsal_fired_final_shot)
		assert(not act_one.story.mutsal_threw_rifle)
		duel.tick(1.9, true)
		assert(act_one.story.mutsal_threw_rifle)
		assert(act_one.story.phase == Story.Phase.HAND_DECISION)
		assert(not act_one.can_leave_for_act_two())

		# The moral decision is made explicitly, never from a failed shot/timer.
		act_one._resolve_hand(hand_choice)
		assert(act_one.story.phase == Story.Phase.COMPLETE)
		assert(act_one.story.hand_choice == hand_choice)
		assert(act_one.story.body_covered)
		assert(act_one.can_leave_for_act_two())
		act_one.queue_free()
		await process_frame

	print("PASS: four area checkpoints and both Act I endings gate the Act II exit.")
	quit(0)
