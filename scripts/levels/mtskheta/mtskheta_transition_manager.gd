
extends Node

const AREA_FILES: Array[String] = [
	"market.tscn",
	"cathedral_precinct.tscn",
	"streets.tscn",
	"terraces.tscn",
	"north_road.tscn",
]

const AREA_WIDTH: int = 2400

var _traveling: bool = false
var _pending_spawn_id: String = ""
var _saved_hp: int = -1
var _saved_max_hp: int = -1
var _saved_vitality: int = -1


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)


func travel_to(scene_path: String, spawn_id: String) -> void:
	if _traveling:
		return

	if not ResourceLoader.exists(scene_path):
		push_error("Scene not found: " + scene_path)
		return

	_save_player_stats()

	_pending_spawn_id = spawn_id
	_traveling = true

	var error_code: Error = get_tree().change_scene_to_file(
		scene_path
	)

	if error_code != OK:
		push_error("Transition failed: " + str(error_code))
		_pending_spawn_id = ""
		_traveling = false


func _on_scene_changed(scene_root: Node) -> void:
	if scene_root.scene_file_path.get_file() not in AREA_FILES:
		return

	var player: CharacterBody2D = (
		scene_root.get_node_or_null("Player") as CharacterBody2D
	)

	if player == null:
		push_error("Mtskheta area is missing Player")
		_traveling = false
		return

	if _traveling:
		var entrance: Marker2D = _find_spawn(
			_pending_spawn_id
		)

		if entrance != null:
			player.global_position = entrance.global_position
		else:
			push_warning(
				"Missing spawn: " + _pending_spawn_id
			)

		player.velocity = Vector2.ZERO
		_restore_player_stats(player)

		_pending_spawn_id = ""
		_traveling = false

	_configure_camera(player)


func _find_spawn(spawn_id: String) -> Marker2D:
	for node: Node in get_tree().get_nodes_in_group(
		"mtskheta_spawn"
	):
		if (
			node is Marker2D
			and node.get("spawn_id") == spawn_id
		):
			return node as Marker2D

	return null


func _save_player_stats() -> void:
	var player: Node = get_tree().get_first_node_in_group(
		"player"
	)

	if player == null:
		return

	var health: Node = player.get_node_or_null(
		"HealthComponent"
	)

	if health != null:
		_saved_hp = int(health.get("current_health"))
		_saved_max_hp = int(health.get("max_health"))

	if _has_property(player, "vitality"):
		_saved_vitality = int(player.get("vitality"))


func _restore_player_stats(player: CharacterBody2D) -> void:
	var health: Node = player.get_node_or_null(
		"HealthComponent"
	)

	if health != null and _saved_max_hp > 0:
		var restored_hp: int = clampi(
			_saved_hp,
			0,
			_saved_max_hp
		)

		health.set("max_health", _saved_max_hp)
		health.set("current_health", restored_hp)
		health.set("is_dead", false)

		health.emit_signal(
			"health_changed",
			restored_hp,
			_saved_max_hp
		)

	if (
		_saved_vitality >= 0
		and _has_property(player, "vitality")
	):
		player.set("vitality", _saved_vitality)


func _configure_camera(player: CharacterBody2D) -> void:
	var camera: Camera2D = player.find_child(
		"Camera2D",
		true,
		false
	) as Camera2D

	if camera == null:
		return

	camera.limit_left = 0
	camera.limit_right = AREA_WIDTH
	camera.limit_top = -400
	camera.limit_bottom = 800


func _has_property(
	object: Object,
	property_name: String
) -> bool:
	for entry: Dictionary in object.get_property_list():
		if String(entry.get("name", "")) == property_name:
			return true

	return false
