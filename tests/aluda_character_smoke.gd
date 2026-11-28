extends SceneTree


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var stage: Node2D = (load("res://scenes/levels/aluda/character_preview.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	var player: CharacterBody2D = stage.get_node("Aluda")
	var slot: ActorVisualSlot = player.get_node("VisualSlot")
	for i in 10:
		await physics_frame
	if not slot.has_visual() or not player.is_on_floor():
		_fail("Aluda or the preview ground did not load")
		return
	Input.action_press("move_right")
	for i in 12:
		await physics_frame
	Input.action_release("move_right")
	if player.velocity.x <= 0.0:
		_fail("Aluda did not move")
		return
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	await process_frame
	await process_frame
	Input.action_release("attack")
	if slot.get_current_animation() != &"attack":
		_fail("Attack state did not reach the visual")
		return
	var fallback := ActorVisual.new()
	var alternate := PackedScene.new()
	if alternate.pack(fallback) != OK:
		_fail("Could not pack alternate visual")
		return
	fallback.free()
	if not slot.set_visual_scene(alternate):
		_fail("Could not replace Aluda's visual")
		return
	Input.action_press("move_left")
	for i in 20:
		await physics_frame
	Input.action_release("move_left")
	if player.velocity.x >= 0.0 or slot.get_active_visual().facing_direction != -1.0:
		_fail("Movement or facing failed after visual replacement")
		return
	stage.queue_free()
	await process_frame
	print("PASS: Aluda moves, animates and accepts a replacement visual.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
