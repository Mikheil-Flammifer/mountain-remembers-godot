extends SceneTree

const Encounter = preload("res://scripts/levels/aluda/rifle_encounter.gd")

func _initialize() -> void:
	var fight = Encounter.new()
	fight.start()
	assert(fight.fire(false) and not fight.loaded)
	assert(not fight.fire(true))
	for i in 4:
		assert(fight.reload_next())
	assert(fight.loaded)
	fight.tick(4.0, true)
	assert(fight.player_health == 2)
	fight.tick(4.0, false)
	assert(fight.player_health == 1)
	assert(fight.fire(true))
	assert(fight.enemy_health == 0 and not fight.active)
	fight.free()
	print("PASS: rifle reload, cover, damage and defeat.")
	quit(0)
