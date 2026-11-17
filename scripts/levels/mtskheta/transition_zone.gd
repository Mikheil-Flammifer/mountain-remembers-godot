extends Area2D

## Two-way district portal. Edge exits travel automatically; doorways need E.
## The transition manager enforces fade completion and a short arrival cooldown.
@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn_id: String = ""
@export var require_interaction: bool = false
@export var prompt_text: String = "E - Enter"

@onready var prompt: Label = $PromptLabel

var _player_inside: bool = false
var _used: bool = false
var _e_was_down: bool = false


func _ready() -> void:
	monitoring = true
	prompt.visible = false
	prompt.text = prompt_text
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	var e_down: bool = Input.is_physical_key_pressed(KEY_E)
	var interact_pressed: bool = e_down and not _e_was_down
	_e_was_down = e_down

	if InputMap.has_action("interact"):
		interact_pressed = interact_pressed or Input.is_action_just_pressed("interact")

	if InputMap.has_action("talk"):
		interact_pressed = interact_pressed or Input.is_action_just_pressed("talk")

	if require_interaction and _player_inside and interact_pressed:
		_start_transition()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_inside = true
	prompt.visible = require_interaction

	if not require_interaction:
		_start_transition()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_inside = false
	prompt.visible = false


func _start_transition() -> void:
	if _used:
		return

	if target_scene.is_empty() or target_spawn_id.is_empty():
		push_error("TransitionZone: destination or spawn ID is missing")
		return

	var manager: Node = get_node_or_null("/root/MtskhetaTransitionManager")
	if manager == null:
		push_error("MtskhetaTransitionManager autoload is missing")
		return

	# When a player arrives near a portal, ignore its body_entered signal
	# during fade-in/cooldown. Do not permanently mark it used.
	if manager.has_method("can_travel") and not manager.can_travel():
		return

	_used = true
	manager.call_deferred("travel_to", target_scene, target_spawn_id)
