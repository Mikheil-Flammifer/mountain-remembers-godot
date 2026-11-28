extends SceneTree
## Act I horse: Aluda mounts the messenger's horse, it gallops with a running
## cycle, and he steps down at the crags.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var HorseScript = load("res://scripts/visuals/actors/horse/horse_visual.gd")
	var horse = HorseScript.new()
	root.add_child(horse)
	horse.update_gait(0.0, 1.0, false, 0.1)
	assert(horse.gait_name() == &"idle")
	horse.update_gait(0.3, 1.0, false, 0.1)
	assert(horse.gait_name() == &"walk")
	horse.update_gait(1.0, 1.0, false, 0.05)
	assert(horse.gait_name() == &"gallop")
	var before: Vector2 = horse.leg_angles(&"fore_near")
	var seat_before: Vector2 = horse.seat_offset
	for i in 6:
		horse.update_gait(1.0, 1.0, false, 0.03)
	assert(horse.leg_angles(&"fore_near") != before)
	assert(horse.seat_offset != seat_before)
	horse.update_gait(1.0, -1.0, false, 0.03)
	assert(horse.scale.x < 0.0)
	horse.queue_free()

	var scene: Node2D = load("res://scenes/levels/aluda/act_one/tracking.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var player = scene.player
	player.set_physics_process(false)
	assert(scene.horse != null and scene.horse_gate != null)
	player.position = Vector2(20, 440)
	assert(not scene.can_mount_horse())  # not before the messenger's report
	scene.story.receive_raid_report()
	assert(scene.can_mount_horse())
	assert(scene.mount_horse())
	assert(player.mounted and scene.horse.get_parent() == player)
	await process_frame
	assert(scene.horse_gate == null)
	player.velocity = Vector2(player.ride_speed, 0)
	player._process(0.05)
	assert(scene.horse.gait_name() == &"gallop")
	assert(player.visual_slot.position.y < -40.0)
	player.position = Vector2(2340, 440)
	scene._update_subarea()
	scene._process(0.016)
	assert(not player.mounted)
	assert(scene.horse.get_parent() == scene)
	assert(is_equal_approx(scene.horse.position.x, 2340.0))
	assert(not scene.can_mount_horse())  # the crags are walked on foot
	print("aluda_horse_smoke: OK")
	quit(0)
