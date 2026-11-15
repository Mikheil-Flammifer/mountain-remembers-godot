
extends Node

const WORLD_MAP_SCENE = preload(
    "res://scenes/world_map/world_map.tscn"
)

var map_instance: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if map_instance == null:
			open_map()
		else:
			close_map()


func open_map() -> void:
	if map_instance != null:
		return

	map_instance = WORLD_MAP_SCENE.instantiate()
	map_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	get_tree().root.add_child(map_instance)
	map_instance.closed.connect(close_map)

	get_tree().paused = true
	print("World map opened")


func close_map() -> void:
	if map_instance == null:
		return

	var old_map: Control = map_instance
	map_instance = null

	get_tree().paused = false
	old_map.queue_free()

	print("World map closed")
