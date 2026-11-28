extends Node2D
## Act 1 tracking section. Story state is owned by this encounter.

const Story = preload("res://scripts/systems/story/act_one_state.gd")
const ALUDA = preload("res://scenes/actors/player/aluda.tscn")
const MESSENGER = preload("res://scenes/visuals/actors/characters/messenger/messenger_visual.tscn")
const RIFLE = preload("res://scripts/levels/aluda/rifle_encounter.gd")
const BROTHER = preload("res://scenes/visuals/actors/characters/mutsal_brother/mutsal_brother_visual.tscn")
const SANATA = preload("res://scenes/visuals/actors/characters/sanata/sanata_visual.tscn")

var story = Story.new()
var player: CharacterBody2D
var message: Label
var prompt: Label
var rifle: RifleEncounter
var brother: Node2D
var _points := [
	{"id": "report", "x": 160.0, "label": "Messenger", "text": "The shepherds were attacked. Raiders took horses, including yours. Follow their trail toward Arkhoti."},
	{"id": "dogs", "x": 430.0, "label": "Sheepfold", "text": "The dogs are silent now. The attack passed before dawn."},
	{"id": "hoofprints", "x": 750.0, "label": "Hoofprints", "text": "Fresh hoofprints climb away from the sheepfold toward the high pasture."},
	{"id": "grass", "x": 1060.0, "label": "Bent grass", "text": "Bent grass and disturbed earth mark a hurried passage."},
	{"id": "river", "x": 1400.0, "label": "River detour", "text": "Sanata: The river stones are wet with fresh prints. The raiders may reach cover while you take this longer path. [New]"},
	{"id": "stones", "x": 1720.0, "label": "Wet stones", "text": "Water on the stones shows where the horses crossed."},
	{"id": "birds", "x": 2050.0, "label": "Birdcalls", "text": "Birdcalls echo over the pasture as the dawn light reaches the crags."},
	{"id": "crags", "x": 2400.0, "label": "The crags", "text": "The trail leads among the rocks. The rifle encounter is the next part to be built."},
]


func _ready() -> void:
	_build_world()
	_build_hud()


func _build_world() -> void:
	var ground := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3500, 120)
	collision.shape = shape
	ground.position = Vector2(1650, 500)
	ground.add_child(collision)
	add_child(ground)
	player = ALUDA.instantiate()
	player.position = Vector2(50, 440)
	add_child(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -110)
	camera.zoom = Vector2(1.6, 1.6)
	camera.position_smoothing_enabled = true
	player.add_child(camera)
	var messenger: Node2D = MESSENGER.instantiate()
	messenger.position = Vector2(160, 440)
	add_child(messenger)
	var sanata: Node2D = SANATA.instantiate()
	sanata.position = Vector2(1400, 440)
	add_child(sanata)
	brother = BROTHER.instantiate()
	brother.position = Vector2(2820, 440)
	brother.visible = false
	add_child(brother)
	rifle = RIFLE.new()
	add_child(rifle)
	rifle.updated.connect(func(text: String): message.text = text)
	rifle.defeated.connect(_on_brother_defeated)
	queue_redraw()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	message = Label.new()
	message.position = Vector2(24, 24)
	message.size = Vector2(950, 90)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 20)
	message.add_theme_color_override("font_outline_color", Color("#202b29"))
	message.add_theme_constant_override("outline_size", 5)
	message.text = "A messenger waits at the sheepfold. Walk to him and press E."
	layer.add_child(message)
	prompt = Label.new()
	prompt.position = Vector2(24, 120)
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_outline_color", Color("#202b29"))
	prompt.add_theme_constant_override("outline_size", 4)
	layer.add_child(prompt)


func _process(delta: float) -> void:
	if rifle.active:
		rifle.tick(delta, player.position.x >= 2500.0 and player.position.x <= 2580.0)
	var point := _nearby_point()
	prompt.text = "E — " + str(point.get("label", "")) if not point.is_empty() else "A / D — Move    Space — Jump"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F or event.keycode == KEY_F:
			rifle.fire(player.position.x > 2580.0 and player.position.x < 2820.0 and player.facing > 0.0)
			return
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			if story.phase == Story.Phase.BROTHER_FIGHT and not rifle.active:
				player.position = Vector2(2510, 440)
				rifle.player_health = 2
				rifle.enemy_health = 1
				rifle.loaded = true
				rifle.reload_step = 0
				rifle.enemy_timer = rifle.ENEMY_FIRE_INTERVAL
				rifle.start()
			else:
				rifle.reload_next()
			return
	if not event.is_action_pressed("talk") or event.is_echo():
		return
	var point := _nearby_point()
	if point.is_empty():
		return
	var id := String(point.id)
	if id == "report":
		story.receive_raid_report()
	elif story.phase == Story.Phase.RAID_REPORT:
		message.text = "Speak to the messenger at the sheepfold first."
		return
	elif id == "river":
		story.visit_river()
		story.meet_sanata()
	elif id == "crags":
		if story.reach_crags():
			brother.visible = true
			rifle.start()
			queue_redraw()
			return
	else:
		story.inspect_trail(StringName(id))
	message.text = str(point.text)


func _on_brother_defeated() -> void:
	story.defeat_brother()
	brother.visible = false


func _nearby_point() -> Dictionary:
	for point: Dictionary in _points:
		if absf(player.position.x - float(point.x)) < 75.0 and absf(player.position.y - 440.0) < 100.0:
			return point
	return {}


func _draw() -> void:
	draw_rect(Rect2(-200, -1000, 3100, 1600), Color("#b9b7a2"))
	draw_colored_polygon(PackedVector2Array([Vector2(-200,380), Vector2(100,130), Vector2(350,310), Vector2(700,30), Vector2(1050,290), Vector2(1450,70), Vector2(1850,330), Vector2(2300,100), Vector2(2800,350), Vector2(2800,500), Vector2(-200,500)]), Color("#788778"))
	draw_rect(Rect2(-200, 440, 3000, 200), Color("#565b47"))
	draw_line(Vector2(-200, 440), Vector2(2800, 440), Color("#a99b78"), 4.0)
	if story.phase >= Story.Phase.BROTHER_FIGHT:
		draw_rect(Rect2(2500, 390, 80, 50), Color("#696b5d"))
	for point: Dictionary in _points:
		if point.id not in ["report", "river"]:
			draw_circle(Vector2(float(point.x), 432), 7.0, Color("#d6bb83"))
