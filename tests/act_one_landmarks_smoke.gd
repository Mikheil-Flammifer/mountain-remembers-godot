extends SceneTree
## Act 1 decorative layers are present, with the same story interactions.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var packed: PackedScene = load("res://scenes/levels/aluda/act_one/tracking.tscn")
	assert(packed != null)
	var scene: Node2D = packed.instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.has_node("KhevsuretiBackground"))
	assert(scene.has_node("RockyPasture"))
	assert(scene.has_node("EnvironmentalLandmarks"))
	assert(scene.get_node("EnvironmentalLandmarks") is Node2D)
	assert(scene.trail_status != null)
	var floor_found := false
	for node in scene.get_children():
		if node is StaticBody2D:
			floor_found = true
			assert(node.get_node("CollisionShape2D") != null)
	assert(floor_found)
	var player: CharacterBody2D = scene.player
	player.set_physics_process(false)
	var interact := InputEventAction.new()
	interact.action = &"talk"
	interact.pressed = true
	player.position = Vector2(160, 440)
	scene._unhandled_input(interact)
	assert(scene.story.phase == scene.Story.Phase.TRACKING)
	for clue_x in [430, 750, 1060, 1720, 2050]:
		player.position = Vector2(clue_x, 440)
		scene._unhandled_input(interact)
	assert(scene.story.trail_clues.size() == 5)
	scene._process(0.2)
	assert(scene.trail_status.text.contains("5 / 5"))
	player.position = Vector2(1400, 440)
	scene._unhandled_input(interact)
	assert(scene.story.visited_river)
	scene.queue_free()
	await process_frame
	print("PASS: Act 1 landscape layers, flat collision and optional visual clues.")
	quit(0)
