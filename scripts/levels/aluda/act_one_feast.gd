extends Node2D
## Opening invented for the game: the raid report interrupts a meal in Shatili.

const Dialogue = preload("res://scripts/ui/aluda_dialogue_panel.gd")
const TRACKING := "res://scenes/levels/aluda/act_one/tracking.tscn"
enum Phase { FEAST, REPORT, LEAVE, HORSE, RIDING }
var phase: Phase = Phase.FEAST
var dialogue: AludaDialoguePanel
var hint: Label
var _transitioning := false
var _meal_time := 0.0


func _ready() -> void:
	$Messenger.visible = false
	dialogue = Dialogue.new()
	add_child(dialogue)
	dialogue.set_location("Shatili castle")
	var layer := CanvasLayer.new()
	add_child(layer)
	hint = Label.new()
	hint.position = Vector2(35, 28)
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color("#f3dfb4"))
	hint.add_theme_color_override("font_outline_color", Color("#1a2020"))
	hint.add_theme_constant_override("outline_size", 5)
	layer.add_child(hint)
	hint.text = "The feast at Shatili   ·   E — Continue"


func _process(delta: float) -> void:
	if phase != Phase.FEAST:
		return
	_meal_time += delta
	for guest in [$Aluda, $GuestUshisha, $GuestAludaBrother, $GuestGela, $GuestBero]:
		guest.rotation = 0.025 * sin(_meal_time * 2.0 + guest.position.x * 0.03)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and dialogue.is_open:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			dialogue.advance()
			return
		if event.keycode == KEY_ESCAPE:
			dialogue.close()
			return
	if not event.is_action_pressed("talk") or event.is_echo() or dialogue.is_open or _transitioning:
		return
	match phase:
		Phase.FEAST: _messenger_arrives()
		Phase.REPORT:
			phase = Phase.LEAVE
			hint.text = "E — Leave the castle"
			dialogue.show_line("Aluda", "My horse too? I will follow their trail toward Arkhoti.")
		Phase.LEAVE: _leave_castle()
		Phase.HORSE: _mount_and_ride()


func _messenger_arrives() -> void:
	phase = Phase.REPORT
	_transitioning = true
	$Messenger.visible = true
	$Messenger.position.x = 1260
	var arrival := create_tween()
	arrival.tween_property($Messenger, "position:x", 1080.0, 0.8)
	arrival.tween_callback(func() -> void:
		_transitioning = false
		hint.text = "E — Answer the messenger"
		dialogue.show_line("Messenger", "Raiders! They attacked the shepherds and stole the horses — Aluda's among them! They are heading toward Arkhoti!")
	)


func _leave_castle() -> void:
	_transitioning = true
	hint.text = "Aluda leaves the feast"
	var departure := create_tween()
	departure.tween_property($Aluda, "position", Vector2(1140, 700), 1.5)
	departure.tween_callback(_show_courtyard)


func _show_courtyard() -> void:
	for child in get_children():
		if child is Node2D and child != $Camera2D and child != $Aluda:
			child.visible = false
	$Aluda.position = Vector2(440, 670)
	$Aluda.z_index = 2
	phase = Phase.HORSE
	_transitioning = false
	hint.text = "E — Mount the horse and follow the raiders"
	queue_redraw()


func _mount_and_ride() -> void:
	phase = Phase.RIDING
	_transitioning = true
	hint.text = "Toward Arkhoti"
	$Aluda.position = Vector2(705, 590)
	var ride := create_tween()
	ride.tween_property($Aluda, "position:x", 1250.0, 2.0)
	ride.parallel().tween_method(_move_horse, 0.0, 545.0, 2.0)
	ride.tween_callback(func() -> void:
		get_tree().set_meta("act_one_feast_report", true)
		get_tree().change_scene_to_file(TRACKING)
	)


var horse_offset := 0.0
func _move_horse(value: float) -> void:
	horse_offset = value
	queue_redraw()


func _draw() -> void:
	if phase not in [Phase.HORSE, Phase.RIDING]:
		return
	draw_rect(Rect2(0, 0, 1280, 800), Color("#687e82"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 550), Vector2(260, 310), Vector2(460, 510), Vector2(760, 270), Vector2(1100, 540), Vector2(1280, 410), Vector2(1280, 800), Vector2(0, 800)]), Color("#405253"))
	draw_rect(Rect2(0, 690, 1280, 110), Color("#4b5143"))
	var o := Vector2(horse_offset, 0)
	draw_rect(Rect2(Vector2(620, 640) + o, Vector2(160, 52)), Color("#543c32"))
	draw_colored_polygon(PackedVector2Array([Vector2(750, 660) + o, Vector2(780, 585) + o, Vector2(818, 590) + o, Vector2(828, 620) + o, Vector2(790, 635) + o, Vector2(785, 685) + o]), Color("#543c32"))
	for x in [640.0, 665.0, 740.0, 765.0]:
		draw_line(Vector2(x, 680) + o, Vector2(x - 4, 735) + o, Color("#302b29"), 9.0)
	draw_line(Vector2(620, 650) + o, Vector2(590, 700) + o, Color("#302b29"), 8.0)
