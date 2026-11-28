extends SceneTree
## Every tree scene under scenes/visuals/environment/trees/ must load as a TreeVisual and draw.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var dir := DirAccess.open("res://scenes/visuals/environment/trees")
	var count := 0
	for file in dir.get_files():
		if not file.ends_with("_tree.tscn"):
			continue
		var tree := (load("res://scenes/visuals/environment/trees/" + file) as PackedScene).instantiate() as TreeVisual
		if tree == null:
			return _fail("%s is not a TreeVisual" % file)
		root.add_child(tree)
		tree.queue_redraw()
		await process_frame
		count += 1
	if count < 6:
		return _fail("expected at least 6 trees, found %d" % count)
	print("PASS: %d tree scenes load and draw." % count)
	quit(0)


func _fail(msg: String) -> void:
	push_error("FAIL: " + msg)
	quit(1)
