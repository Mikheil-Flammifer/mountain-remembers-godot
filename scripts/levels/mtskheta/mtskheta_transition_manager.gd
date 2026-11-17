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
const AREA_WIDTH: int = 2400
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
var _curtain: ColorRect
var _next_travel_at_ms: int = 0


func _ready() -> void:
	_build_curtain()
	get_tree().scene_changed.connect(_on_scene_changed)


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
	_begin_scene_change(scene_path, spawn_id)


func activate_checkpoint(scene_path: String, spawn_id: String) -> void:
	if not ResourceLoader.exists(scene_path) or spawn_id.is_empty():
		push_error("Mtskheta checkpoint: invalid scene or spawn ID")
		return

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

	# Complete the change explicitly: do not depend on scene_changed
	# resetting _traveling (which caused the previous stuck-travel bug).
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
	else:
		push_warning("Missing Mtskheta spawn ID: " + _pending_spawn_id)

	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	_restore_player_stats(player)
	_configure_camera(player)
	_bind_player_death(player)

	# Allow one frame for the new scene's transforms, still under black.
	await get_tree().process_frame
	if is_instance_valid(player):
		_snap_camera(player)

	await _finish_travel()
	print("TRAVEL COMPLETE: ", destination.name)


func _finish_travel() -> void:
	# Do not allow a new transition while the arriving scene is fading in.
	_pending_spawn_id = ""
	await _fade_to(0.0)
	_next_travel_at_ms = Time.get_ticks_msec() + TRANSITION_REARM_MS
	_traveling = false


func _on_scene_changed(scene_root: Node) -> void:
	if scene_root.scene_file_path.get_file() not in AREA_FILES:
		return

	# Travel has its own post-load setup while the screen is covered.
	if _traveling:
		return

	# Setup when starting the game directly in a Mtskheta district.
	var player: CharacterBody2D = _find_player(scene_root)
	if player != null:
		_configure_camera(player)
		_bind_player_death(player)


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
	var camera: Camera2D = player.find_child("Camera2D", true, false) as Camera2D
	if camera == null:
		return
	camera.make_current()
	camera.force_update_scroll()
	camera.reset_smoothing()
	camera.force_update_scroll()


func _configure_camera(player: CharacterBody2D) -> void:
	var camera: Camera2D = player.find_child("Camera2D", true, false) as Camera2D
	if camera == null:
		return

	camera.limit_left = 0
	var current: Node = get_tree().current_scene
	camera.limit_right = ORIGINAL_MTSKHETA_WIDTH if current != null and current.scene_file_path.get_file() == "mtskheta.tscn" else AREA_WIDTH
	camera.limit_top = -400
	camera.limit_bottom = 800
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
