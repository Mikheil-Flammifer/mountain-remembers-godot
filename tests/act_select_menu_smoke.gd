extends SceneTree
## Act menu: only Act I opens on a fresh save; each act opens only after the
## previous one is finished; unbuilt acts never open.

const Progress = preload("res://scripts/systems/story/act_progress.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Progress.save_path = "user://test_act_progress_menu.cfg"
	Progress.reset()
	assert(Progress.is_unlocked(1))
	assert(not Progress.is_unlocked(2))
	assert(not Progress.is_unlocked(3))

	var menu: Control = load("res://scenes/ui/act_select_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	assert(not menu.buttons[0].disabled)
	assert(menu.buttons[1].disabled)
	assert(not menu.start_act(2))

	Progress.mark_complete(1, {"hand_choice": 2})
	menu.refresh()
	assert(not menu.buttons[1].disabled)
	assert(menu.buttons[2].disabled)
	assert(not menu.start_act(3))

	Progress.mark_complete(2, {"dream_choice": 1})
	menu.refresh()
	assert(Progress.is_unlocked(3) and not Progress.is_built(3))
	assert(menu.buttons[2].disabled)
	assert(not menu.start_act(3))

	assert(menu.start_act(2))
	assert(get_meta("aluda_act_one_hand_choice") == 2)
	remove_meta("aluda_act_one_hand_choice")
	Progress.reset()
	print("PASS: act menu unlocks acts in order and never opens one early.")
	quit(0)
