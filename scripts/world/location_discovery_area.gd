extends Area2D
## Optional trigger. Add to a level as an Area2D with a CollisionShape2D.
## Set location_id in the Inspector, and have the Xizane player enter the area.

@export var location_id: String = "shatili"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is XizanePlayer:
		WorldState.enter_location(location_id)
