class_name BaseNPC
extends MtskhetaInvestigationNPC

## Reusable NPC layer.
##
## IMPORTANT:
## This extends the existing MtskhetaInvestigationNPC instead of replacing it.
##
## Because of that:
## - investigation_controller.gd still recognizes this NPC
## - npc_id still works
## - display_name still works
## - cloak_color still works
## - highlighting still works
## - existing dialogue logic does not need to change
##
## This script only adds reusable visual behaviour.

@export_group("Facing")
@export var face_player: bool = true
@export var face_player_distance: float = 460.0

@export_group("Idle")
@export var idle_enabled: bool = true
@export var idle_sway_degrees: float = 0.75
@export var idle_sway_speed: float = 1.3

var _player: Node2D
var _base_rotation: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _idle_time: float = 0.0


func _ready() -> void:
	super._ready()

	_base_rotation = rotation
	_base_scale = scale

	call_deferred("_find_player")


func _process(delta: float) -> void:
	_idle_time += delta

	if not is_instance_valid(_player):
		_find_player()

	_update_facing()
	_update_idle()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D

	if _player != null:
		return

	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return

	_player = current_scene.get_node_or_null("Player") as Node2D

	if _player == null:
		_player = current_scene.get_node_or_null("Xizane") as Node2D


func _update_facing() -> void:
	if not face_player:
		scale = _base_scale
		return

	if not is_instance_valid(_player):
		return

	var distance: float = global_position.distance_to(
		_player.global_position
	)

	if distance > face_player_distance:
		return

	var direction: float = signf(
		_player.global_position.x - global_position.x
	)

	if is_zero_approx(direction):
		return

	scale.x = absf(_base_scale.x) * direction
	scale.y = _base_scale.y


func _update_idle() -> void:
	if not idle_enabled:
		rotation = _base_rotation
		return

	var sway: float = deg_to_rad(idle_sway_degrees) * sin(
		_idle_time * idle_sway_speed
	)

	rotation = _base_rotation + sway