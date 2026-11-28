extends SceneTree
## Act II scene: locked without a finished Act I; with one, every step is a
## deliberate action and only the dagger action records the dream choice.

const META := ["aluda_act_one_hand_choice", "aluda_act_two_dream_choice", "aluda_act_two_complete"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var saved := {}
	for key in META:
		if has_meta(key):
			saved[key] = get_meta(key)
		if has_meta(key):
			remove_meta(key)
	var packed: PackedScene = load("res://scenes/levels/aluda/act_two/night_camp.tscn")
	assert(packed != null)

	# Without a finished Act I the camp stays locked.
	var locked: Node2D = packed.instantiate()
	root.add_child(locked)
	await process_frame
	assert(locked.locked)
	assert(locked.story.phase == locked.story.Phase.LOCKED)
	locked.queue_free()
	await process_frame

	for hand in [1, 2]:
		for dream in [1, 2]:
			set_meta("aluda_act_one_hand_choice", hand)
			if has_meta("aluda_act_two_dream_choice"):
				remove_meta("aluda_act_two_dream_choice")
			var scene: Node2D = packed.instantiate()
			root.add_child(scene)
			await process_frame
			scene.player.set_physics_process(false)
			var P = scene.story.Phase
			assert(not scene.locked and scene.hand_choice == hand)
			assert(scene.story.phase == P.ARRIVAL)

			_at(scene, scene.WEAPON_X)
			scene._interact()
			assert(scene.story.phase == P.ARRIVAL)
			_at(scene, scene.FIRE_X); scene._interact()
			_at(scene, scene.WEAPON_X); scene._interact()
			_at(scene, scene.LOOKOUT_X); scene._interact()
			assert(scene.story.phase == P.WATCH_KEPT)
			_at(scene, scene.FIRE_X); scene._interact()
			assert(scene.story.phase == P.DREAM_GATHERING)
			assert(scene.get_node("NightArt").get("dream_mode"))
			_at(scene, scene.FEAST_X); scene._interact()
			_at(scene, scene.SHADE_X); scene._interact()
			assert(scene.story.phase == P.DREAM_DUEL)

			# Missed guards change nothing; guarded exchanges end the duel.
			scene.player.set("_blocking", false)
			scene.shade_attack()
			assert(scene.story.duel_rounds_remaining == 3)
			scene.player.set("_blocking", true)
			for i in range(3):
				scene.shade_attack()
			scene.player.set("_blocking", false)
			assert(scene.story.phase == P.DREAM_DAGGER)
			assert(not has_meta("aluda_act_two_dream_choice"))

			_at(scene, scene.LOWER_X if dream == 1 else scene.STRIKE_X)
			scene._interact()
			assert(scene.story.phase == P.AWAKENED)
			assert(int(scene.story.dream_choice) == dream)
			assert(get_meta("aluda_act_two_dream_choice") == dream)
			assert(not scene.get_node("NightArt").get("dream_mode"))
			_at(scene, scene.ROAD_X); scene._interact()
			assert(scene.story.phase == P.AWAKENED)
			_at(scene, scene.FIRE_X); scene._interact()
			_at(scene, scene.ROAD_X); scene._interact()
			assert(scene.story.phase == P.COMPLETE)
			assert(get_meta("aluda_act_two_complete") == true)
			assert(get_meta("aluda_act_one_hand_choice") == hand)
			scene.queue_free()
			await process_frame

	for key in META:
		if has_meta(key):
			remove_meta(key)
		if saved.has(key):
			set_meta(key, saved[key])
	print("PASS: Act II locked without Act I; full camp, dream duel and both dream outcomes.")
	quit(0)


func _at(scene: Node2D, x: float) -> void:
	scene.player.position = Vector2(x, 440)
