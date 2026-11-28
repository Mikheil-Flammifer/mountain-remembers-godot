extends SceneTree
## The Act 1 tracking level has four continuous modular landscape regions.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var source: PackedScene = load("res://scenes/levels/aluda/act_one/tracking.tscn")
	assert(source != null)
	var scene: Node2D = source.instantiate()
	root.add_child(scene)
	await process_frame

	var subareas: Node2D = scene.get_node("Subareas")
	assert(subareas.get_child_count() == 4)
	assert(subareas.has_node("ShepherdsFold"))
	assert(subareas.has_node("WindPasture"))
	assert(subareas.has_node("SanataFord"))
	assert(subareas.has_node("ArkhotiCrags"))
	assert(scene.area_banner != null)
	assert(scene.current_subarea == 0)
	assert(scene.area_banner.current_title == "THE SHEPHERDS' FOLD")

	var player: CharacterBody2D = scene.player
	player.set_physics_process(false)
	assert(scene.story.phase == scene.Story.Phase.RAID_REPORT)

	# Step across every boundary and return across one; story state never resets.
	var xs := [649.0, 650.0, 1239.0, 1240.0, 1919.0, 1920.0, 2600.0, 100.0]
	var expected := [0, 1, 1, 2, 2, 3, 3, 0]
	for i in range(xs.size()):
		player.position = Vector2(xs[i], 440.0)
		scene._process(0.016)
		assert(scene.current_subarea == expected[i])
		assert(scene.story.phase == scene.Story.Phase.RAID_REPORT)
		assert(not scene.area_banner.current_title.is_empty())
	assert(scene.area_banner.visit_count == 5)

	# The modular art scenes are presentation only; physics floor is unchanged.
	var floor_count := 0
	for node in scene.get_children():
		if node is StaticBody2D:
			floor_count += 1
			assert(node.get_node("CollisionShape2D") != null)
	assert(floor_count == 1)
	for child in subareas.get_children():
		assert(child is Node2D)
		for descendant in child.get_children():
			assert(not descendant is CollisionObject2D)

	scene.queue_free()
	await process_frame
	print("PASS: Four Act 1 subareas, boundaries, banner and original quest state.")
	quit(0)
