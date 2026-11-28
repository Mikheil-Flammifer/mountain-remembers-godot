extends SceneTree
## Every character appearance under resources/visuals/actors/ must load and animate.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var dir := DirAccess.open("res://resources/visuals/actors")
	var count := 0
	for id in dir.get_directories():
		var path := "res://resources/visuals/actors/%s/default_appearance.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var data := load(path) as ActorVisualData
		if data == null or not data.is_valid():
			return _fail("%s has no valid appearance" % id)
		var visual := data.visual_scene.instantiate() as ActorVisual
		if visual == null:
			return _fail("%s visual is not an ActorVisual" % id)
		root.add_child(visual)
		await process_frame
		var state := ActorVisualState.new()
		state.is_grounded = true
		state.velocity = Vector2(150, 0)
		state.facing_direction = -1.0
		visual.update_visual(state, 0.1)
		if visual.get_current_animation() != &"run" or visual.facing_direction != -1.0:
			return _fail("%s did not run or turn" % id)
		visual.queue_free()
		count += 1
	if count < 3:
		return _fail("Expected at least 3 character appearances, found %d" % count)
	print("PASS: %d character visuals load, run and turn." % count)
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
