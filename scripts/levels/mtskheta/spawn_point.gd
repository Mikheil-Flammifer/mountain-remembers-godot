
extends Marker2D

@export var spawn_id: String = "start"


func _ready() -> void:
	add_to_group("mtskheta_spawn")
