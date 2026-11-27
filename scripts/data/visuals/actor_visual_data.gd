
class_name ActorVisualData
extends Resource
## Configurable appearance definition for an actor.
## Contains visual configuration, not runtime gameplay state.


@export_group("Identity")

@export var appearance_id: StringName = &"default"
@export var display_name: String = "Default Appearance"

@export_multiline var description: String = ""


@export_group("Visual Scene")

@export var visual_scene: PackedScene
@export var visual_offset: Vector2 = Vector2.ZERO


@export_group("Appearance")

@export var visual_scale: Vector2 = Vector2.ONE
@export var base_tint: Color = Color.WHITE

@export_enum("Left:-1", "Right:1")
var default_facing: int = 1


@export_group("Preview")

@export var preview_texture: Texture2D


func is_valid() -> bool:
	return (
		visual_scene != null
		and visual_scale.x > 0.0
		and visual_scale.y > 0.0
	)
