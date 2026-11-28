extends SceneTree


func _initialize() -> void:
	_check.call_deferred()


func _check() -> void:
	var preview: Node2D = load("res://scenes/levels/aluda/character_preview.tscn").instantiate()
	root.add_child(preview)
	var player: CharacterBody2D = preview.get_node("Aluda")
	player.position = Vector2(1100, 440)
	Input.action_press("move_right")
	for i in 90:
		await physics_frame
	Input.action_release("move_right")
	assert(player.position.x < 1160 and player.position.y < 450, "Preview edge must stop the player")
	preview.queue_free()
	await process_frame

	var scene: Node2D = load("res://scenes/levels/aluda/act_one/tracking.tscn").instantiate()
	root.add_child(scene)
	player = scene.player
	player.position = Vector2(570, 440)
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
	assert(player.position.x < 620, "Stone should stop walking")
	Input.action_press("jump")
	for i in 50:
		await physics_frame
	Input.action_release("jump")
	Input.action_release("move_right")
	assert(player.position.x > 680 and player.position.y < 450, "Stone should be jumpable")
	player.position = Vector2(1800, 440)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
	assert(player.position.x < 1840, "Ford stone should stop walking")
	Input.action_press("jump")
	for i in 50:
		await physics_frame
	Input.action_release("jump")
	Input.action_release("move_right")
	assert(player.position.x > 1920 and player.position.y < 450, "Ford stone should be jumpable")
	player.position = Vector2(3850, 440)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	for i in 90:
		await physics_frame
	Input.action_release("move_right")
	assert(player.position.x < 3905 and player.position.y < 450, "Act 1 edge must stop the player")
	scene.queue_free()
	await process_frame
	print("PASS: preview and Act 1 boundaries, walkable and jumpable stone.")
	quit(0)
