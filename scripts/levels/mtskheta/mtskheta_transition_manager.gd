extends Node

## Mtskheta travel manager: fade -> scene change -> spawn/camera snap -> fade in.
## Install as the existing MtskhetaTransitionManager autoload.
## Do not enable the older MtskhetaTravelFX autoload at the same time.

const AREA_FILES: Array[String] = [
	"mtskheta.tscn",
	"market.tscn",
	"cathedral_precinct.tscn",
	"streets.tscn",
	"terraces.tscn",
	"north_road.tscn",
]
const JVARI_SCENE_DIR: String = "res://scenes/levels/jvari/"
const AREA_WIDTH: int = 2400
const TERRACES_WIDTH: int = 5100
const ORIGINAL_MTSKHETA_WIDTH: int = 3600
const FADE_DURATION: float = 0.24
const MAX_LOAD_FRAMES: int = 120
const TRANSITION_REARM_MS: int = 500

const DEFAULT_CHECKPOINT_SCENE: String = "res://scenes/levels/mtskheta/market.tscn"
const DEFAULT_CHECKPOINT_SPAWN: String = "start"

var _traveling: bool = false
var _pending_spawn_id: String = ""
var _saved_hp: int = -1
var _saved_max_hp: int = -1
var _saved_vitality: int = -1
var _checkpoint_scene: String = DEFAULT_CHECKPOINT_SCENE
var _checkpoint_spawn_id: String = DEFAULT_CHECKPOINT_SPAWN
var _jvari_checkpoint_scene: String = ""
var _jvari_checkpoint_spawn: String = ""
var _curtain: ColorRect
var _next_travel_at_ms: int = 0


func _ready() -> void:
	_build_curtain()

	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)

	call_deferred("_configure_initial_scene")

func _configure_initial_scene() -> void:
	# Autoloads are created before the project's main scene.
	# Wait until Streets is completely available, then configure it
	# exactly like scenes entered through the travel system.
	for _frame in range(10):
		await get_tree().process_frame

		var current: Node = get_tree().current_scene

		if current != null and current.is_node_ready():
			_on_scene_changed(current)
			return

	push_warning("MtskhetaTransitionManager: initial scene was not ready")	


func _build_curtain() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "MtskhetaCurtainLayer"
	layer.layer = 100
	add_child(layer)

	_curtain = ColorRect.new()
	_curtain.name = "MtskhetaCurtain"
	_curtain.color = Color(0.035, 0.042, 0.055)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_curtain)
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.modulate.a = 0.0


func _fade_to(opacity: float) -> void:
	var tween: Tween = create_tween()
	var fade_step: PropertyTweener = tween.tween_property(
		_curtain, "modulate:a", opacity, FADE_DURATION
	)
	fade_step.set_trans(Tween.TRANS_SINE)
	fade_step.set_ease(Tween.EASE_IN_OUT)
	await tween.finished


## A brief rearm delay prevents the arrival entrance from triggering again.
func can_travel() -> bool:
	return not _traveling and Time.get_ticks_msec() >= _next_travel_at_ms


func travel_to(scene_path: String, spawn_id: String) -> void:
	if not can_travel():
		return
	if not ResourceLoader.exists(scene_path) or spawn_id.is_empty():
		push_error("Mtskheta travel: invalid scene or spawn ID: " + scene_path)
		return

	_save_player_stats()
	if _saved_hp == 0:
		return
	_begin_scene_change(scene_path, spawn_id)


func activate_checkpoint(scene_path: String, spawn_id: String) -> void:
	if not ResourceLoader.exists(scene_path) or spawn_id.is_empty():
		push_error("Mtskheta checkpoint: invalid scene or spawn ID")
		return

	if _is_jvari(scene_path):
		_jvari_checkpoint_scene = scene_path
		_jvari_checkpoint_spawn = spawn_id
	else:
		_checkpoint_scene = scene_path
		_checkpoint_spawn_id = spawn_id
	_save_player_stats()
	print("[Checkpoint] Activated: ", scene_path, " / ", spawn_id)


func respawn_at_checkpoint() -> void:
	if _traveling:
		return

	_save_player_stats()
	if _saved_max_hp > 0:
		_saved_hp = _saved_max_hp
	var active_scene := get_tree().current_scene
	if active_scene != null and _is_jvari(active_scene.scene_file_path):
		_begin_scene_change(_jvari_checkpoint_scene, _jvari_checkpoint_spawn)
	else:
		_begin_scene_change(_checkpoint_scene, _checkpoint_spawn_id)


func _begin_scene_change(scene_path: String, spawn_id: String) -> void:
	_pending_spawn_id = spawn_id
	_traveling = true

	# Stay in the old scene until the screen is fully covered.
	await _fade_to(1.0)

	var error_code: Error = get_tree().change_scene_to_file(scene_path)
	if error_code != OK:
		push_error("Mtskheta scene change failed: " + str(error_code))
		await _finish_travel()
		return

	# Wait for the destination to be ready before placing the player.
	var destination: Node = null
	for _frame in range(MAX_LOAD_FRAMES):
		await get_tree().process_frame
		var current: Node = get_tree().current_scene
		if current != null and current.scene_file_path == scene_path and current.is_node_ready():
			destination = current
			break

	if destination == null:
		push_error("Mtskheta travel timed out: " + scene_path)
		await _finish_travel()
		return

	var player: CharacterBody2D = _find_player(destination)
	if player == null:
		push_error("Mtskheta scene has no Player/Xizane: " + scene_path)
		await _finish_travel()
		return

	var entrance: Marker2D = _find_spawn(_pending_spawn_id)
	if entrance != null:
		player.global_position = entrance.global_position
		if _is_jvari(scene_path):
			_jvari_checkpoint_scene = scene_path
			_jvari_checkpoint_spawn = _pending_spawn_id
	else:
		push_warning("Missing travel spawn ID: " + _pending_spawn_id)
		if _is_jvari(scene_path):
			_set_default_jvari_checkpoint(scene_path)

	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	_restore_player_stats(player)
	_configure_camera(player)
	_bind_player_death(player)

	# Let the destination's transforms update while the curtain is opaque.
	await get_tree().process_frame
	if is_instance_valid(player):
		_snap_camera(player)

	await _finish_travel()

	var camera: Camera2D = player.find_child(
		"Camera2D", true, false
	) as Camera2D

	print("TRAVEL COMPLETE: ", destination.name)
	print("Current scene: ", get_tree().current_scene.scene_file_path)
	print("Player position: ", player.global_position)

	if camera != null:
		print("Camera current: ", camera.is_current())
		print("Camera position: ", camera.global_position)
		print("Camera screen center: ", camera.get_screen_center_position())
		print("Camera limits: ", camera.limit_left, " / ", camera.limit_right)


func _finish_travel() -> void:
	# Keep travel locked until the fade-in completes.
	_pending_spawn_id = ""
	await _fade_to(0.0)
	_next_travel_at_ms = Time.get_ticks_msec() + TRANSITION_REARM_MS
	_traveling = false


func _on_scene_changed(scene_root: Node = null) -> void:
	if scene_root == null:
		scene_root = get_tree().current_scene

	if scene_root == null:
		return

	var path := scene_root.scene_file_path
	if path.get_file() not in AREA_FILES and not _is_jvari(path):
		return

	if _traveling:
		return

	var player: CharacterBody2D = _find_player(scene_root)

	if player != null:
		if _is_jvari(path):
			_set_default_jvari_checkpoint(path)
		_configure_camera(player)
		_bind_player_death(player)


func _is_jvari(scene_path: String) -> bool:
	return scene_path.begins_with(JVARI_SCENE_DIR)


func _set_default_jvari_checkpoint(scene_path: String) -> void:
	_jvari_checkpoint_scene = scene_path
	_jvari_checkpoint_spawn = "from_previous"


func _find_player(scene_root: Node) -> CharacterBody2D:
	var player: CharacterBody2D = scene_root.get_node_or_null("Player") as CharacterBody2D
	if player == null:
		player = scene_root.get_node_or_null("Xizane") as CharacterBody2D
	return player


func _find_spawn(spawn_id: String) -> Marker2D:
	for node: Node in get_tree().get_nodes_in_group("mtskheta_spawn"):
		if node is Marker2D and str(node.get("spawn_id")) == spawn_id:
			return node as Marker2D
	return null


func _snap_camera(player: CharacterBody2D) -> void:
	var camera: Camera2D = player.find_child(
		"Camera2D", true, false
	) as Camera2D

	if camera == null:
		return

	var was_smoothing: bool = camera.position_smoothing_enabled

	camera.position_smoothing_enabled = false
	camera.make_current()
	camera.reset_smoothing()
	camera.force_update_scroll()

	camera.position_smoothing_enabled = was_smoothing


func _configure_camera(player: CharacterBody2D) -> void:
	var camera: Camera2D = player.find_child(
		"Camera2D", true, false
	) as Camera2D

	if camera == null:
		return

	var current: Node = get_tree().current_scene
	var filename: String = current.scene_file_path.get_file()

	var bounds := Rect2i(0, -400, 2400, 1200)

	if _is_jvari(current.scene_file_path):
		bounds = current.call("camera_bounds")
	elif filename == "terraces.tscn":
		bounds.size.x = 5100
	elif filename == "mtskheta.tscn":
		bounds.size.x = 3600
	elif filename == "streets.tscn":
		bounds = Rect2i(0, -400, 2400, 1200)

	camera.limit_left = bounds.position.x
	camera.limit_right = bounds.end.x
	camera.limit_top = bounds.position.y
	camera.limit_bottom = bounds.end.y

	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0

	_snap_camera(player)


func _save_player_stats() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var health: Node = player.get_node_or_null("HealthComponent")
	if health != null:
		_saved_hp = int(health.get("current_health"))
		_saved_max_hp = int(health.get("max_health"))

	if _has_property(player, "vitality"):
		_saved_vitality = int(player.get("vitality"))


func _restore_player_stats(player: CharacterBody2D) -> void:
	var health: Node = player.get_node_or_null("HealthComponent")
	if health != null and _saved_max_hp > 0:
		var restored_hp: int = clampi(_saved_hp, 0, _saved_max_hp)
		health.set("max_health", _saved_max_hp)
		health.set("current_health", restored_hp)
		health.set("is_dead", false)
		health.emit_signal("health_changed", restored_hp, _saved_max_hp)

	if _saved_vitality >= 0 and _has_property(player, "vitality"):
		player.set("vitality", _saved_vitality)


func _bind_player_death(player: CharacterBody2D) -> void:
	var health: Node = player.get_node_or_null("HealthComponent")
	if health == null or not health.has_signal("died"):
		return

	var handler: Callable = Callable(self, "_on_player_died")
	if not health.is_connected("died", handler):
		health.connect("died", handler)


func _on_player_died() -> void:
	var death_scene: Node = get_tree().current_scene
	await get_tree().create_timer(1.0).timeout
	if _traveling or not is_instance_valid(death_scene):
		return
	if get_tree().current_scene != death_scene:
		return
	respawn_at_checkpoint()


func _has_property(object: Object, property_name: String) -> bool:
	for entry: Dictionary in object.get_property_list():
		if str(entry.get("name", "")) == property_name:
			return true
	return false
