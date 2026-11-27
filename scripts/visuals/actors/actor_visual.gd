
class_name ActorVisual
extends Node2D
## Base interface for replaceable actor visual implementations.


signal animation_started(animation_name: StringName)
signal animation_finished(animation_name: StringName)


@export_group("Appearance")

@export var default_facing: float = 1.0
@export var visual_scale: Vector2 = Vector2.ONE
@export var base_tint: Color = Color.WHITE


var facing_direction: float = 1.0
var current_animation: StringName = &"idle"


func _ready() -> void:
	set_facing(default_facing)
	modulate = base_tint


# State interface

func update_visual(
	_state: ActorVisualState,
	_delta: float
) -> void:
	pass


# Facing

func set_facing(direction: float) -> void:
	if is_zero_approx(direction):
		return

	facing_direction = 1.0 if direction > 0.0 else -1.0

	scale = Vector2(
		absf(visual_scale.x) * facing_direction,
		visual_scale.y
	)


# Animation interface

func play_animation(animation_name: StringName) -> void:
	if current_animation == animation_name:
		return

	current_animation = animation_name
	animation_started.emit(animation_name)


func finish_animation() -> void:
	animation_finished.emit(current_animation)


func get_current_animation() -> StringName:
	return current_animation


# Visual effects interface

func flash_damage() -> void:
	pass


func flash_heal() -> void:
	pass


func flash_block(_perfect_guard: bool = false) -> void:
	pass


func reset_visual() -> void:
	current_animation = &"idle"
	modulate = base_tint
	set_facing(default_facing)
