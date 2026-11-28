extends SceneTree
## The Act 1 bottom dialogue is independent of story triggers and world movement.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var scene: Node2D = (load("res://scenes/levels/aluda/act_one/tracking.tscn") as PackedScene).instantiate()
	assert(scene != null)
	root.add_child(scene)
	await process_frame

	var dialogue: AludaDialoguePanel = scene.dialogue_panel
	assert(dialogue != null)
	assert(not dialogue.is_open)

	var player: CharacterBody2D = scene.player
	player.set_physics_process(false)
	var talk := InputEventAction.new()
	talk.action = &"talk"
	talk.pressed = true

	# The messenger's speech appears in the panel, not a top-of-screen label.
	player.position = Vector2(160, 440)
	scene._unhandled_input(talk)
	assert(scene.story.phase == scene.Story.Phase.TRACKING)
	assert(dialogue.is_open and dialogue.current_speaker == "Messenger")
	assert(dialogue.current_text.contains("shepherds"))

	dialogue.reveal_all()
	assert(dialogue.is_open)
	dialogue.advance()
	assert(not dialogue.is_open)

	# Environmental observations use a distinct narrator name.
	player.position = Vector2(750, 440)
	scene._unhandled_input(talk)
	assert(scene.story.trail_clues.has(&"hoofprints"))
	assert(dialogue.current_speaker == "The trail")

	# Sanata's detour still records the same optional story state.
	player.position = Vector2(1400, 440)
	scene._unhandled_input(talk)
	assert(scene.story.visited_river and scene.story.met_sanata)
	assert(dialogue.current_speaker == "Sanata")
	assert(not dialogue.current_text.contains("[New]"))

	dialogue.close()
	assert(not dialogue.is_open)
	assert(scene.prompt != null and scene.trail_status != null)

	scene.queue_free()
	await process_frame
	print("PASS: Aluda bottom dialogue panel, speaker labels, dismissal and story state.")
	quit(0)
