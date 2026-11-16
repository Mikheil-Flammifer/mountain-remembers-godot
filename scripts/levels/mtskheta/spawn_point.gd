extends Marker2D

## The manager uses this ID to place Xizane at the correct entrance.
@export var spawn_id: String = "start"


func _ready() -> void:
	add_to_group("mtskheta_spawn")
