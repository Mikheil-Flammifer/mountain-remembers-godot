extends SceneTree


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var scene: Node2D = (load("res://scenes/levels/aluda/act_one/tracking.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var player: CharacterBody2D = scene.player
	player.set_physics_process(false)
	var interact := InputEventAction.new()
	interact.action = &"talk"
	interact.pressed = true
	player.position = Vector2(750, 440)
	scene._unhandled_input(interact)
	assert(scene.story.trail_clues.is_empty())
	player.position = Vector2(160, 440)
	scene._unhandled_input(interact)
	player.position = Vector2(750, 440)
	scene._unhandled_input(interact)
	assert(scene.story.trail_clues.has(&"hoofprints"))
	player.position = Vector2(1400, 440)
	scene._unhandled_input(interact)
	assert(scene.story.visited_river and scene.story.met_sanata)
	player.position = Vector2(2400, 440)
	scene._unhandled_input(interact)
	assert(scene.story.phase == scene.Story.Phase.BROTHER_FIGHT)
	scene.queue_free()
	await process_frame
	print("PASS: Raid report, tracking, Sanata and crags interactions.")
	quit(0)
