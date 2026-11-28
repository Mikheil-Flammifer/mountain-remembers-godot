extends SceneTree


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var lab: Control = (load("res://scenes/debug/actor_visual_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	await process_frame
	var slot: ActorVisualSlot = lab.get_node("Stage/VisualSlot")
	var picker: OptionButton = lab.get_node("Panel/Margin/Controls/Mode")
	var facing: OptionButton = lab.get_node("Panel/Margin/Controls/Facing")
	var expected := ["idle", "run", "jump", "fall", "dash", "attack_1", "attack_2", "attack_up", "attack_down", "block", "rest", "climb"]
	if not slot.has_visual() or picker.item_count != expected.size():
		push_error("Lab failed to load the Xizane visual or preview modes")
		quit(1)
		return
	for index in expected.size():
		picker.select(index)
		await process_frame
		await process_frame
		if slot.get_current_animation() != expected[index]:
			push_error("Preview %d did not select %s" % [index, expected[index]])
			quit(1)
			return
	picker.select(0)
	facing.select(1)
	await process_frame
	await process_frame
	if slot.get_active_visual().facing_direction != -1.0:
		push_error("Facing control did not reach the visual")
		quit(1)
		return
	lab.queue_free()
	await process_frame
	print("PASS: Xizane visual lab modes and facing")
	quit(0)
