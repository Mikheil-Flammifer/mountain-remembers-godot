class_name CathedralStoryHUD
extends "res://scripts/ui/story_hud.gd"

## Reuses the existing dialogue/journal UI; keeps the objective below
## Xizane's upper-left health bar.


func _ready() -> void:
	super._ready()
	layer = 110
	_objective.position = Vector2(24, 130)
	_objective.size = Vector2(1050, 38)
