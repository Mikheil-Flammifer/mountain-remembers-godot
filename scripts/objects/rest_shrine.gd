extends Area2D
## Lit wayside cross: E to heal and set the *real* checkpoint/respawn marker.
@export var spawn_id: String = "rest_1"
var _inside: bool = false
var _prompt: Label
var _lit: bool = false
var _elapsed: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var sensor := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(170, 140)
	sensor.shape = rect
	sensor.position = Vector2(0, -68)
	add_child(sensor)
	_prompt = Label.new()
	_prompt.position = Vector2(-130, -177)
	_prompt.custom_minimum_size = Vector2(260, 30)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color("#f5dfaa"))
	_prompt.text = "E  -  Rest at the wayside cross"
	_prompt.visible = false
	add_child(_prompt)
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)

func _on_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = true
		_prompt.visible = true

func _on_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_inside = false
		_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _inside or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and (key.keycode == KEY_E or key.physical_keycode == KEY_E):
		var player: Node = get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("set_resting"):
			player.call("set_resting", true)
				
		if player != null:
			var health: Node = player.get_node_or_null("HealthComponent")
			if health != null and health.has_method("restore_full_health"):
				health.call("restore_full_health")
		var manager: Node = get_node_or_null("/root/MtskhetaTransitionManager")
		if manager != null and manager.has_method("activate_checkpoint"):
			manager.call("activate_checkpoint", get_tree().current_scene.scene_file_path, spawn_id)
		_lit = true
		_prompt.text = "Rested  -  Respawn point saved"
		get_viewport().set_input_as_handled()
		queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _inside or _lit:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-57,-14,114,15), Color("#4e4c41"))
	draw_rect(Rect2(-50,-24,100,13), Color("#a79a7b"))
	draw_rect(Rect2(-8,-115,16,90), Color("#69685a"))
	draw_rect(Rect2(-29,-94,58,13), Color("#c4b08c"))
	var glow: float = 0.65 + sin(_elapsed*4.0)*0.20
	draw_circle(Vector2(36,-53), 17.0, Color("#dba765",0.20 if _lit else 0.11))
	draw_circle(Vector2(36,-53), 8.0 + glow * 3.0, Color("#e6a95d"))
	draw_colored_polygon(PackedVector2Array([Vector2(35,-78),Vector2(27,-50),Vector2(37,-37),Vector2(45,-54)]),Color("#f8d49a"))
