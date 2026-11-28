extends SceneTree
## Every castle prop scene must load as a CastleProp and draw; the feast scene must load.


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var dir := DirAccess.open("res://scenes/visuals/environment/castle")
	var count := 0
	for file in dir.get_files():
		if not file.ends_with(".tscn"):
			continue
		var prop := (load("res://scenes/visuals/environment/castle/" + file) as PackedScene).instantiate() as CastleProp
		if prop == null:
			return _fail("%s is not a CastleProp" % file)
		root.add_child(prop)
		await process_frame
		count += 1
	if count < 14:
		return _fail("expected 14 castle props, found %d" % count)
	var feast := (load("res://scenes/levels/aluda/prologue/shatili_castle_feast.tscn") as PackedScene).instantiate()
	if feast == null or feast.get_node_or_null("Aluda") == null or feast.get_node_or_null("ChiefChair") == null:
		return _fail("castle feast scene is missing Aluda or his chair")
	root.add_child(feast)
	await process_frame
	print("PASS: %d castle props and the feast scene load and draw." % count)
	quit(0)


func _fail(msg: String) -> void:
	push_error("FAIL: " + msg)
	quit(1)
