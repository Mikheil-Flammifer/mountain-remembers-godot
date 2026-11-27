
class_name ActorVisualSlot
extends Node2D
## Manages the active visual representation of an actor.
## Gameplay communicates with this slot instead of individual
## sprites, polygons, bones or animation nodes.


signal visual_changed(visual: ActorVisual)


@export_group("Visual Configuration")

@export var initial_visual_scene: PackedScene


var _active_visual: ActorVisual


func _ready() -> void:
	# Support visual scenes placed directly in the editor.
	for child in get_children():
		if child is ActorVisual:
			_active_visual = child as ActorVisual
			break

	# Otherwise instantiate the configured visual scene.
	if not has_visual() and initial_visual_scene != null:
		set_visual_scene(initial_visual_scene)


# Visual management

func set_visual_scene(scene: PackedScene) -> bool:
	if scene == null:
		push_warning("ActorVisualSlot: Visual scene is null.")
		return false

	var instance: Node = scene.instantiate()

	if not instance is ActorVisual:
		push_error(
			"ActorVisualSlot: Scene root must extend ActorVisual."
		)

		instance.free()
		return false

	var new_visual := instance as ActorVisual

	# Preserve the existing visual if validation fails.
	# Remove it only after validating the replacement.
	clear_visual()

	_active_visual = new_visual
	add_child(_active_visual)

	visual_changed.emit(_active_visual)

	return true


func clear_visual() -> void:
	if not has_visual():
		_active_visual = null
		return

	var previous_visual: ActorVisual = _active_visual
	_active_visual = null

	remove_child(previous_visual)
	previous_visual.queue_free()


func get_active_visual() -> ActorVisual:
	if not has_visual():
		return null

	return _active_visual


func has_visual() -> bool:
	return (
		is_instance_valid(_active_visual)
		and not _active_visual.is_queued_for_deletion()
	)


# State forwarding

func update_visual(
	state: ActorVisualState,
	delta: float
) -> void:
	if not has_visual() or state == null:
		return

	_active_visual.update_visual(state, delta)


# Animation controls

func play_animation(animation_name: StringName) -> void:
	if not has_visual():
		return

	_active_visual.play_animation(animation_name)


func get_current_animation() -> StringName:
	if not has_visual():
		return &""

	return _active_visual.get_current_animation()


func set_facing(direction: float) -> void:
	if not has_visual():
		return

	_active_visual.set_facing(direction)


# Visual effects

func flash_damage() -> void:
	if has_visual():
		_active_visual.flash_damage()


func flash_heal() -> void:
	if has_visual():
		_active_visual.flash_heal()


func flash_block(perfect_guard: bool = false) -> void:
	if has_visual():
		_active_visual.flash_block(perfect_guard)


func reset_visual() -> void:
	if has_visual():
		_active_visual.reset_visual()
