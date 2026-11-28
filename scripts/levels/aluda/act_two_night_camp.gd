extends Node2D
## Act II: night camp, weapon check, watch, the dream feast, the mirror duel
## with Mutsal's shade and the dagger decision. ActTwoState owns the sequence;
## this scene only turns player actions into state calls and presents them.
## Act II is entered only after Act I is complete and never edits Act I state.

const Story = preload("res://scripts/systems/story/act_two_state.gd")
const ALUDA = preload("res://scenes/actors/player/aluda.tscn")
const DIALOGUE = preload("res://scripts/ui/aluda_dialogue_panel.gd")
const BANNER = preload("res://scripts/ui/act_one_area_banner.gd")
const Progress = preload("res://scripts/systems/story/act_progress.gd")
const MENU_SCENE := "res://scenes/ui/act_select_menu.tscn"

const WEAPON_X := 380.0
const FIRE_X := 540.0
const LOOKOUT_X := 960.0
const ROAD_X := 1800.0
const FEAST_X := 700.0
const SHADE_X := 1080.0
const LOWER_X := 850.0
const STRIKE_X := 1220.0
const SHADE_ATTACK_INTERVAL := 1.8
const SHADE_REACH := 150.0

var story: ActTwoState = Story.new()
var locked: bool = false
var hand_choice: int = 0
var player: CharacterBody2D
var dialogue_panel: AludaDialoguePanel
var _hint: Label
var _objective: Label
var _night_art: Node2D
var _shade_timer: float = SHADE_ATTACK_INTERVAL
var _leaving: bool = false


func _ready() -> void:
	var tree: SceneTree = get_tree()
	hand_choice = int(tree.get_meta("aluda_act_one_hand_choice", 0))
	# Act I sets this only after its COMPLETE phase, so it doubles as the gate.
	var act_one_done: bool = tree.has_meta("aluda_act_one_hand_choice")
	_night_art = get_node("NightArt")
	_build_floor_and_player()
	_build_hud()
	if not story.begin(hand_choice, act_one_done):
		locked = true
		_dialogue("Narrator", "Act II opens only after Act I is finished. Press E to return to the act menu.")
		return
	# Arriving here with a hand choice means Act I was finished: remember it.
	Progress.mark_complete(1, {"hand_choice": hand_choice})
	story.phase_changed.connect(func(_p) -> void: _sync_art())
	var banner := BANNER.new()
	banner.name = "ActTwoBanner"
	add_child(banner)
	banner.announce("ACT II — NIGHT CAMP", "A night of silence above the mountain road")
	var memory: String = "Aluda remembers covering Mutsal rather than taking his hand. The old custom weighs on him."
	if hand_choice == Story.HAND_CUT:
		memory = "Two arms hang from Aluda's saddle. Victory brought him no peace."
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
	_objective = _make_label("Objective", 16)
	_objective.position = Vector2(25, 22)
	overlay.add_child(_objective)
	_hint = _make_label("ActionHint", 17)
	_hint.anchor_left = 0.15
	_hint.anchor_right = 0.85
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_top = -63.0
	_hint.offset_bottom = -25.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(_hint)


func _make_label(label_name: String, size: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#e9d8b5"))
	label.add_theme_color_override("font_outline_color", Color("#121e29"))
	label.add_theme_constant_override("outline_size", 4)
	return label


func _near(x: float, reach: float = 88.0) -> bool:
	return absf(player.position.x - x) < reach


func _process(delta: float) -> void:
	if locked:
		_objective.text = "ACT II   ·   Locked until Act I is complete"
		_hint.text = "E — Return to the act menu"
		return
	match story.phase:
		Story.Phase.ARRIVAL:
			_set_text("Tend the fire", "E — Tend the fire" if _near(FIRE_X) else "A / D — Walk to the rock shelter")
		Story.Phase.FIRE_TENDED:
			_set_text("Check your rifle", "E — Clean and load the rifle" if _near(WEAPON_X) else "Your rifle rests against the rock")
		Story.Phase.WEAPON_CHECKED:
			_set_text("Keep watch over the road", "E — Keep watch" if _near(LOOKOUT_X) else "Walk to the lookout stone")
		Story.Phase.WATCH_KEPT:
			_set_text("Sleep beside the fire", "E — Sleep" if _near(FIRE_X) else "Return to the campfire")
		Story.Phase.DREAM_GATHERING:
			if not story.feast_witnessed:
				_set_text("THE DREAM   ·   The dead gather", "E — Sit among the warriors" if _near(FEAST_X) else "Silent warriors sit around a meal")
			else:
				_set_text("THE DREAM   ·   Mutsal waits", "E — Face Mutsal" if _near(SHADE_X, 120.0) else "Mutsal's shade stands apart")
		Story.Phase.DREAM_DUEL:
			_update_duel(delta)
			_set_text("THE DREAM   ·   The duel repeats  (%d)" % story.duel_rounds_remaining,
				"G — Hold your guard as he strikes.  H only brings more rounds.")
		Story.Phase.DREAM_DAGGER:
			if _near(LOWER_X, 85.0):
				_set_text("THE DREAM   ·   A dagger is offered", "E — Turn the dagger aside")
			elif _near(STRIKE_X, 90.0):
				_set_text("THE DREAM   ·   A dagger is offered", "E — Strike Mutsal in the dream")
			else:
				_set_text("THE DREAM   ·   A dagger is offered", "Walk to either memory and press E. No timed decision.")
		Story.Phase.AWAKENED:
			if not story.reflected:
				_set_text("A changed heart", "E — Reflect by the fire" if _near(FIRE_X) else "Return to the fire")
			else:
				_set_text("Dawn on the road home", "E — Break camp and go home" if _near(ROAD_X, 110.0) else "Walk east to the road")
		Story.Phase.COMPLETE:
			_set_text("Act II complete", "E — Return to the act menu")
	_hint.visible = not dialogue_panel.is_open


func _set_text(objective: String, hint: String) -> void:
	_objective.text = objective if objective.begins_with("THE DREAM") else "ACT II   ·   " + objective
	_hint.text = hint


func _update_duel(delta: float) -> void:
	if not _near(SHADE_X, SHADE_REACH):
		return
	_shade_timer -= delta
	if _shade_timer <= 0.0:
		_shade_timer = SHADE_ATTACK_INTERVAL
		shade_attack()


## The shade swings. A raised guard counts as a parry; a missed guard costs
## nothing and makes no choice, the exchange simply repeats.
func shade_attack() -> void:
	if story.phase != Story.Phase.DREAM_DUEL:
		return
	if _is_guarding():
		story.parry()
		if story.phase == Story.Phase.DREAM_DAGGER:
			_dialogue("Mutsal", "I want to die, and I do not die. Kill me! Let this passing world stay with you, and let me leave the land. Live on, sons of the Khevsurs, with raids and the swing of swords.")


func _is_guarding() -> bool:
	return bool(player.get("_blocking"))


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
	if event.is_action_pressed("attack") and not event.is_echo():
		if story.phase == Story.Phase.DREAM_DUEL and _near(SHADE_X, SHADE_REACH):
			story.strike_in_duel()
	if event.is_action_pressed("talk") and not event.is_echo():
		_interact()


func _interact() -> void:
	if locked or story.phase == Story.Phase.COMPLETE:
		if not _leaving:
			_leaving = true
			get_tree().change_scene_to_file(MENU_SCENE)
		return
	match story.phase:
		Story.Phase.ARRIVAL:
			if _near(FIRE_X) and story.tend_fire():
				_dialogue("Aluda", "The fire takes. Before I rest, the rifle must be ready.")
		Story.Phase.FIRE_TENDED:
			if _near(WEAPON_X) and story.check_weapon():
				var line: String = "Powder, bullet, ramrod, priming. The horn Mutsal broke still holds a little."
				_dialogue("Aluda", line)
		Story.Phase.WEAPON_CHECKED:
			if _near(LOOKOUT_X) and story.keep_watch():
				_dialogue("Aluda", "Only wind on the road. No Kist rides after me tonight.")
		Story.Phase.WATCH_KEPT:
			if _near(FIRE_X) and story.sleep():
				player.position = Vector2(560, 440)
				dialogue_panel.set_chapter_location("ACT II", "THE DREAM")
				_dialogue("Narrator", "Darkness falls, the waters weep, the skirt of night covers us. It is the hour when stars flicker, dew falls on the grass, and the souls of the dead come out of their graves.")
		Story.Phase.DREAM_GATHERING:
			if not story.feast_witnessed and _near(FEAST_X):
				story.witness_feast()
				_dialogue("Aluda", "A dead man lay before us; Khevsurs sat at the wake, ready for a raid, some stood at the door. I sat, and someone set a bowl before me: a man's flesh in broth. 'Eat!' something called. 'Don't stand there dumbstruck. Bring Aluda more hot broth and meat.'")
			elif story.feast_witnessed and _near(SHADE_X, 120.0) and story.face_mutsal():
				_shade_timer = SHADE_ATTACK_INTERVAL
				_dialogue("Aluda", "All at once someone seized my hand and laid a dagger's hilt in it. I looked: it was Mutsal, in bronze chain mail, the mark of our fight on his chest. He stood like a rock, unbroken; no tear fell from his eye.")
		Story.Phase.DREAM_DAGGER:
			if _near(LOWER_X, 85.0):
				_resolve_dream(Story.DreamChoice.LOWER_DAGGER)
			elif _near(STRIKE_X, 90.0):
				_resolve_dream(Story.DreamChoice.STRIKE)
		Story.Phase.AWAKENED:
			if not story.reflected and _near(FIRE_X) and story.reflect():
				if story.dream_choice == Story.DreamChoice.LOWER_DAGGER:
					_dialogue("Aluda", "A dead enemy remains a man. I cannot look at the trophies as before.")
				else:
					_dialogue("Aluda", "The old law still calls to me. I will trust the custom of my fathers.")
			elif story.reflected and _near(ROAD_X, 110.0):
				_finish_act()


func _resolve_dream(choice: int) -> void:
	if not story.decide_dream(choice):
		return
	# Carry forward only a choice made by the player, never a timer or a failure.
	get_tree().set_meta("aluda_act_two_dream_choice", int(choice))
	dialogue_panel.set_chapter_location("ACT II", "NIGHT CAMP")
	player.position = Vector2(510, 440)
	if choice == Story.DreamChoice.LOWER_DAGGER:
		_dialogue("Aluda", "Bad dreams tormented me; that is why my heart is troubled. In the dream I turned his dagger aside.")
	else:
		_dialogue("Aluda", "Bad dreams tormented me; that is why my heart is troubled. In the dream my hand did what he begged.")


func _finish_act() -> void:
	if not story.break_camp():
		return
	get_tree().set_meta("aluda_act_two_complete", true)
	Progress.mark_complete(2, {"dream_choice": int(story.dream_choice)})
	var banner := BANNER.new()
	add_child(banner)
	banner.announce("ACT II COMPLETE", "Act II is saved as finished. Press E for the act menu.")


func _sync_art() -> void:
	var dreaming: bool = story.phase in [Story.Phase.DREAM_GATHERING, Story.Phase.DREAM_DUEL, Story.Phase.DREAM_DAGGER]
	_night_art.set("dream_mode", dreaming)
	_night_art.set("show_shade", story.phase in [Story.Phase.DREAM_GATHERING, Story.Phase.DREAM_DUEL])
	_night_art.set("show_dagger_markers", story.phase == Story.Phase.DREAM_DAGGER)
	_night_art.set("fire_lit", story.phase != Story.Phase.ARRIVAL)
	_night_art.queue_redraw()


func _dialogue(speaker: String, line: String) -> void:
	dialogue_panel.show_line(speaker, line)
