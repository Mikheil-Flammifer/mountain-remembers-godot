extends SceneTree
## Run with a fresh APPDATA directory. The test creates and removes a save fixture.

const PLAYER := preload("res://scenes/player/player.tscn")
const WOLF := preload("res://scenes/enemies/mountain_wolf.tscn")
const SHRINE := preload("res://scenes/objects/rest_shrine.tscn")
const SAVE := "user://xizane_progression.json"

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if FileAccess.file_exists(SAVE):
		push_error("Use a fresh test user-data directory.")
		quit(1)
		return
	var fixture := FileAccess.open(SAVE, FileAccess.WRITE)
	if fixture == null:
		push_error("Could not write the test save fixture.")
		quit(1)
		return
	fixture.store_string(JSON.stringify({
		"score": 200, "healing_stones": 2, "collected_stones": {"legacy": true},
		"upgrades": {"blade": 2}, "lost_score": 7,
		"lost_scene": "res://scenes/levels/mtskheta/streets.tscn",
		"lost_position": [50.0, 100.0],
	}))
	fixture.close()

	var world := Node2D.new()
	world.scene_file_path = "res://scenes/levels/mtskheta/north_road.tscn"
	root.add_child(world)
	current_scene = world
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1000, 40)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	floor_body.position.y = 170.0
	world.add_child(floor_body)

	var player := PLAYER.instantiate() as XizanePlayer
	player.position = Vector2(0, 98)
	world.add_child(player)
	await _ticks(25)
	_check(player.is_on_floor(), "Player should land on the test floor")
	_check(player.get_score() == 200 and player.healing_stones == 2, "Legacy score and stones")
	_check(player.has_collected_healing_stone("legacy") and player.combat.damage == 10, "Legacy pickup and upgrade")
	_check(player.visual_slot.get_active_visual() is XizanePolygonVisual, "Default appearance wiring")
	_check(player.begin_ladder_climb(), "Enter climb through player API")
	player.set_ladder_climb_phase(0.5)
	await process_frame
	await process_frame
	_check(player.visual_slot.get_current_animation() == &"climb", "Climb pose reaches the visual")
	player.end_ladder_climb(Vector2.ZERO)

	var replacement := PackedScene.new()
	var simple_visual := ActorVisual.new()
	var sprite := Sprite2D.new()
	simple_visual.add_child(sprite)
	sprite.owner = simple_visual
	_check(replacement.pack(simple_visual) == OK, "Alternate visual packs")
	simple_visual.free()
	_check(player.visual_slot.set_visual_scene(replacement), "Alternate scene replaces the polygon rig")
	_check(player.visual_slot.get_child_count() == 1, "Slot contains one visual after replacement")
	var start_x := player.position.x
	Input.action_press(&"move_left")
	await _ticks(10)
	Input.action_release(&"move_left")
	_check(player.position.x < start_x - 5.0, "Movement works with an alternate visual")
	_check(player.visual_slot.get_active_visual().facing_direction == -1.0, "Alternate visual receives facing")
	player.visual_slot.clear_visual()
	await _ticks(5)

	var wolf := WOLF.instantiate() as MountainWolf
	wolf.position = player.position + Vector2(-74, 0)
	world.add_child(wolf)
	wolf.set_physics_process(false)
	var energy := player.stamina.current_stamina
	Input.action_press(&"attack")
	await _ticks(13)
	Input.action_release(&"attack")
	_check(player.stamina.current_stamina < energy, "Attack consumes stamina with no visual")
	_check(wolf.health == wolf.max_health - 10, "Attack damage is independent of both rigs")
	await _ticks(16)
	wolf.take_hit(wolf.max_health, Vector2.ZERO)
	_check(wolf.dead and player.get_score() == 205, "Wolf death awards score")

	# The existing player supports the block action as well as its physical keys.
	InputMap.add_action(&"block")
	Input.action_press(&"block")
	await _ticks(2)
	var hp := player.health.current_health
	energy = player.stamina.current_stamina
	player.receive_enemy_hit(12, player.position + Vector2(-65, 0))
	_check(player.is_blocking() and player.health.current_health == hp, "Front guard prevents damage")
	_check(player.stamina.current_stamina < energy, "Guard consumes energy")
	Input.action_release(&"block")
	await _ticks(2)
	InputMap.erase_action(&"block")
	player.receive_enemy_hit(20, player.position + Vector2(65, 0), 0.0)
	_check(player.use_healing_stone() and player.health.current_health == hp, "Healing works with no visual")
	_check(player.recover_lost_score() == 7 and player.recover_lost_score() == 0, "Lost score is recovered once")
	_check(player.collect_healing_stone("new") and not player.collect_healing_stone("new"), "Pickup ID is recorded once")
	await _ticks(9)

	var shrine := SHRINE.instantiate() as Area2D
	shrine.position = player.position + Vector2(0, 45)
	world.add_child(shrine)
	await _ticks(4)
	_press_key(KEY_E)
	var menu := _find_menu(shrine)
	_check(player.is_resting() and menu != null and menu.visible, "Shrine opens its menu and rests player")
	_press_key(KEY_1)
	_check(player.get_upgrade_level("blade") == 3 and player.combat.damage == 12, "Shrine shortcut purchases next upgrade")
	_press_key(KEY_E)
	_check(not player.is_resting() and menu != null and not menu.visible, "Standing closes the shrine menu")

	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	_check(result is Dictionary and result.get("score") == 2 and result.get("lost_score") == 0, "Saved score and recovery state")
	_check(result is Dictionary and result.get("upgrades", {}).get("blade") == 3, "Saved level uses the existing schema")
	world.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if _failures == 0:
		print("PASS: Replaceable visuals, movement, combat, shrine upgrades, and legacy progression.")
	quit(0 if _failures == 0 else 1)


func _find_menu(shrine: Node) -> ShrineUpgradeMenu:
	for child in shrine.get_children():
		if child is ShrineUpgradeMenu:
			return child
	return null


func _press_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	root.push_input(event)


func _ticks(count: int) -> void:
	for step in count:
		await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
