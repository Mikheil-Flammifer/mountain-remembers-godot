extends Node2D
## First playable zone. WorldState is optional during initial setup.

func _ready() -> void:
	var world_state: Node = get_node_or_null("/root/WorldState")
	if world_state != null and world_state.has_method("enter_location"):
		world_state.call("enter_location", "mtskheta")
	print("[Mtskheta] Level ready. A/D to move, Space to jump, M for map.")
