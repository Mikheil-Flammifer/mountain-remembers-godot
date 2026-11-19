class_name MtskhetaInvestigationHUD
extends "res://scripts/ui/story_hud.gd"

## Reuse the existing StoryHUD. Place objective below the HP display.
## Layer 50 stays below the travel manager's fade curtain (layer 100).


func _ready() -> void:
    super._ready()
    layer = 50
    _objective.position = Vector2(24, 130)
    _objective.size = Vector2(1050, 38)


func add_journal_note(note: String) -> void:
    _journal_text.text += "\n\n" + note
