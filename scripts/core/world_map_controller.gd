
extends Node

const WORLD_MAP_SCENE: PackedScene = preload(
    "res://scenes/world_map/world_map.tscn"
)

var _overlay: CanvasLayer = null
var _active_map: Control = null
var _map_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not InputMap.has_action("open_map"):
		InputMap.add_action("open_map")

	if InputMap.action_get_events("open_map").is_empty():
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = KEY_M
		InputMap.action_add_event("open_map", key)

	print("[WorldMapController] Ready")


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event

	if not key_event.pressed or key_event.echo:
		return

	# Temporary discovery test: F9 -> Shatili
	if key_event.keycode == KEY_F9:
		WorldState.enter_location("shatili")
		print("[WorldState] Current: ",
			WorldState.current_location_id)
		get_viewport().set_input_as_handled()
		return

	if key_event.is_action_pressed("open_map"):
		get_viewport().set_input_as_handled()

		if _map_open:
			close_map()
		else:
			open_map()

	elif key_event.keycode == KEY_ESCAPE and _map_open:
		get_viewport().set_input_as_handled()
		close_map()


func open_map() -> void:
	if _map_open:
		return

	if get_tree().paused:
		push_warning("Game is already paused")
		return

	_overlay = CanvasLayer.new()
	_overlay.name = "WorldMapOverlay"
	_overlay.layer = 100
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().root.add_child(_overlay)

	_active_map = WORLD_MAP_SCENE.instantiate() as Control

	if _active_map == null:
		push_error("Could not instantiate WorldMap")
		_overlay.queue_free()
		_overlay = null
		return

	_overlay.add_child(_active_map)
	_active_map.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_active_map.closed.connect(close_map)

	_map_open = true
	get_tree().paused = true

	print("[WorldMap] OPENED")


func close_map() -> void:
	if not _map_open:
		return

	_map_open = false
	_active_map = null

	get_tree().paused = false

	if is_instance_valid(_overlay):
		_overlay.queue_free()

	_overlay = null

	print("[WorldMap] CLOSED")
