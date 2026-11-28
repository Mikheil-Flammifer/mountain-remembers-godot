extends Node2D
## Act II opening: camp, watch, dream, and an explicit dagger action.
## This chapter receives the Act I hand choice from SceneTree metadata.
## The rest of Act II will be developed in subsequent scenes.

const Story = preload("res://scripts/systems/story/act_one_state.gd")
const ALUDA = preload("res://scenes/actors/player/aluda.tscn")
const DIALOGUE = preload("res://scripts/ui/aluda_dialogue_panel.gd")
const BANNER = preload("res://scripts/ui/act_one_area_banner.gd")

enum Stage { ARRIVAL, WATCH, DREAM, AWAKENED }
enum DreamChoice { UNDECIDED, LOWER_DAGGER, STRIKE }

var stage: Stage = Stage.ARRIVAL
var dream_choice: DreamChoice = DreamChoice.UNDECIDED
var hand_choice: int = Story.HandChoice.UNDECIDED
var player: CharacterBody2D
var dialogue_panel: AludaDialoguePanel
var _hint: Label
var _objective: Label
var _night_art: Node2D


func _ready() -> void:
	var tree: SceneTree = get_tree()
	hand_choice = int(tree.get_meta("aluda_act_one_hand_choice", Story.HandChoice.UNDECIDED))
	_night_art = get_node("NightArt")
	_build_floor_and_player()
	_build_hud()
	var banner := BANNER.new()
	banner.name = "ActTwoBanner"
	add_child(banner)
	banner.announce("ACT II — NIGHT CAMP", "A night of silence above the mountain road")
	var memory: String = "Mutsal's body remains among the crags. Aluda cannot forget the rifle he threw."
	if hand_choice == Story.HandChoice.SPARE:
		memory = "Aluda remembers covering Mutsal rather than taking his hand. The old custom weighs on him."
	elif hand_choice == Story.HandChoice.CUT:
		memory = "The severed hand weighs heavily upon Aluda. Victory brought him no peace."
	_dialogue("Aluda", memory)


func _build_floor_and_player() -> void:
	var ground := StaticBody2D.new()
	ground.name = "CampGround"
	ground.position = Vector2(700, 500)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2700, 120)
	shape.shape = rectangle
	ground.add_child(shape)
	add_child(ground)
	player = ALUDA.instantiate()
	player.name = "Aluda"
	player.position = Vector2(190, 440)
	add_child(player)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, -115)
	camera.zoom = Vector2(1.6, 1.6)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.5
	camera.limit_left = -250
	camera.limit_right = 1980
	player.add_child(camera)


func _build_hud() -> void:
	dialogue_panel = DIALOGUE.new()
	dialogue_panel.name = "DialoguePanel"
	add_child(dialogue_panel)
	dialogue_panel.set_chapter_location("ACT II", "NIGHT CAMP")
	var hud := CanvasLayer.new()
	hud.name = "NightHUD"
	hud.layer = 5
	add_child(hud)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(overlay)
	_objective = Label.new()
	_objective.name = "Objective"
	_objective.position = Vector2(25, 22)
	_objective.add_theme_font_size_override("font_size", 16)
	_objective.add_theme_color_override("font_color", Color("#e9d8b5"))
	_objective.add_theme_color_override("font_outline_color", Color("#121e29"))
	_objective.add_theme_constant_override("outline_size", 4)
	overlay.add_child(_objective)
	_hint = Label.new()
	_hint.name = "ActionHint"
	_hint.anchor_left = 0.15
	_hint.anchor_right = 0.85
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_top = -63.0
	_hint.offset_bottom = -25.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 17)
	_hint.add_theme_color_override("font_color", Color("#e9d8b5"))
	_hint.add_theme_color_override("font_outline_color", Color("#121e29"))
	_hint.add_theme_constant_override("outline_size", 4)
	overlay.add_child(_hint)


func _process(_delta: float) -> void:
	var near_fire: bool = absf(player.position.x - 540.0) < 88.0
	match stage:
		Stage.ARRIVAL:
			_objective.text = "ACT II   ·   Tend the fire"
			_hint.text = "E — Tend the fire" if near_fire else "A / D — Walk to the rock shelter"
		Stage.WATCH:
			_objective.text = "ACT II   ·   Keep watch, then sleep"
			_hint.text = "E — Sleep beside the fire" if near_fire else "Return to the campfire"
		Stage.DREAM:
			_objective.text = "THE DREAM   ·   A dagger is offered"
			if absf(player.position.x - 850.0) < 85.0:
				_hint.text = "E — Turn the dagger aside"
			elif absf(player.position.x - 1220.0) < 90.0:
				_hint.text = "E — Strike Mutsal in the dream"
			else:
				_hint.text = "Walk to either memory and press E. No timed decision."
		Stage.AWAKENED:
			_objective.text = "ACT II   ·   A changed heart"
			_hint.text = "E — Reflect by the fire" if near_fire else "The dream has ended"
	_hint.visible = not dialogue_panel.is_open


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if dialogue_panel.is_open and key in [KEY_ENTER, KEY_KP_ENTER]:
			dialogue_panel.advance()
			get_viewport().set_input_as_handled()
			return
		if dialogue_panel.is_open and key == KEY_ESCAPE:
			dialogue_panel.close()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("talk") and not event.is_echo():
		_interact()


func _interact() -> void:
	match stage:
		Stage.ARRIVAL:
			if absf(player.position.x - 540.0) < 88.0:
				stage = Stage.WATCH
				_dialogue("Aluda", "The fire takes. I will keep watch until the ridge falls silent.")
		Stage.WATCH:
			if absf(player.position.x - 540.0) < 88.0:
				stage = Stage.DREAM
				player.position = Vector2(700, 440)
				_night_art.set("dream_mode", true)
				_night_art.queue_redraw()
				dialogue_panel.set_chapter_location("ACT II", "THE DREAM")
				_dialogue("Mutsal", "In the dream, Mutsal offers his dagger and asks for another blow. Will I repeat the old law?")
		Stage.DREAM:
			if absf(player.position.x - 850.0) < 85.0:
				_resolve_dream(DreamChoice.LOWER_DAGGER)
			elif absf(player.position.x - 1220.0) < 90.0:
				_resolve_dream(DreamChoice.STRIKE)
		Stage.AWAKENED:
			if absf(player.position.x - 540.0) < 88.0:
				if dream_choice == DreamChoice.LOWER_DAGGER:
					_dialogue("Aluda", "A dead enemy remains a man. I cannot return to the old certainty.")
				else:
					_dialogue("Aluda", "The old law still calls to me, even after such a dream.")


func _resolve_dream(choice: DreamChoice) -> void:
	if stage != Stage.DREAM or dream_choice != DreamChoice.UNDECIDED:
		return
	dream_choice = choice
	# Carry forward only a choice made by the player, not a timer or failure.
	get_tree().set_meta("aluda_act_two_dream_choice", int(choice))
	stage = Stage.AWAKENED
	_night_art.set("dream_mode", false)
	_night_art.queue_redraw()
	dialogue_panel.set_chapter_location("ACT II", "NIGHT CAMP")
	player.position = Vector2(510, 440)
	if choice == DreamChoice.LOWER_DAGGER:
		_dialogue("Aluda", "I turned the dagger away. Dawn has not yet come, but I know what the dream demanded.")
	else:
		_dialogue("Aluda", "In the dream my hand obeyed the old custom. I woke with the weight of it.")


func _dialogue(speaker: String, line: String) -> void:
	dialogue_panel.show_line(speaker, line)
