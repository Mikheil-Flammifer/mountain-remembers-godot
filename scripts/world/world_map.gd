extends Control
## Interactive world map using a real parchment map image.

signal closed

const WorldLocations = preload("res://scripts/world/world_locations.gd")
const MAP_TEXTURE := preload("res://assets/ui/world_map/kazbek_highlands_antique_map.png")

const MIN_ZOOM := 0.45
const MAX_ZOOM := 2.2
const PANEL_WIDTH := 290.0
const MARGIN := 22.0
const MARKER_RADIUS := 7.0
const SELECTED_MARKER_RADIUS := 10.0

var _zoom: float = 0.72
var _pan: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_distance: float = 0.0
var _last_mouse: Vector2 = Vector2.ZERO
var _selected_id: String = "mtskheta"
var _discovered: Dictionary = {}
var _details: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for location in WorldLocations.LOCATIONS:
		_discovered[location["id"]] = location["known"]

	_create_ui()
	_update_details()
	queue_redraw()


func discover_location(location_id: String) -> void:
	_discovered[location_id] = true
	_update_details()
	queue_redraw()


func _create_ui() -> void:
	var sidebar := PanelContainer.new()
	sidebar.name = "DetailsPanel"
	sidebar.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	sidebar.offset_left = -PANEL_WIDTH - MARGIN
	sidebar.offset_right = -MARGIN
	sidebar.offset_top = 75
	sidebar.offset_bottom = -MARGIN
	sidebar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sidebar)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	sidebar.add_child(column)

	var heading := Label.new()
	heading.text = "WORLD MAP"
	heading.add_theme_font_size_override("font_size", 18)
	column.add_child(heading)

	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.add_theme_font_size_override("font_size", 16)
	column.add_child(_details)

	var help := Label.new()
	help.text = "Drag: pan\nWheel: zoom\nClick: inspect\nM / Esc: close"
	help.add_theme_color_override("font_color", Color(0.7, 0.66, 0.57))
	column.add_child(help)

	var close_button := Button.new()
	close_button.text = "Close map"
	close_button.pressed.connect(_close)
	column.add_child(close_button)


func _update_details() -> void:
	if _details == null:
		return

	for location in WorldLocations.LOCATIONS:
		if location["id"] == _selected_id:
			var known: bool = _discovered.get(_selected_id, false)
			_details.text = "%s\n\n%s" % [
				location["name"] if known else "Undiscovered",
				location["description"] if known else "Explore the world to reveal this place."
			]
			return


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.is_action_pressed("open_map"):
			get_viewport().set_input_as_handled()
			_close()


func _close() -> void:
	closed.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event

		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button_event.pressed:
			_zoom_at(mouse_button_event.position, 1.12)
			accept_event()

		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button_event.pressed:
			_zoom_at(mouse_button_event.position, 1.0 / 1.12)
			accept_event()

		elif mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.pressed:
				_dragging = true
				_drag_distance = 0.0
				_last_mouse = mouse_button_event.position
			else:
				if _dragging and _drag_distance < 9.0:
					_select_nearest(mouse_button_event.position)
				_dragging = false
			accept_event()

	elif event is InputEventMouseMotion and _dragging:
		var motion_event: InputEventMouseMotion = event
		var delta: Vector2 = motion_event.position - _last_mouse

		_pan += delta
		_drag_distance += delta.length()
		_last_mouse = motion_event.position

		queue_redraw()
		accept_event()


func _zoom_at(pointer: Vector2, scale_factor: float) -> void:
	var map_before: Vector2 = _screen_to_map(pointer)
	_zoom = clampf(_zoom * scale_factor, MIN_ZOOM, MAX_ZOOM)
	_pan = pointer - _map_to_screen(map_before)
	queue_redraw()


func _map_to_screen(map_position: Vector2) -> Vector2:
	var map_center: Vector2 = WorldLocations.MAP_SIZE / 2.0
	return (map_position - map_center) * _zoom + size / 2.0 + _pan


func _screen_to_map(screen_position: Vector2) -> Vector2:
	var map_center: Vector2 = WorldLocations.MAP_SIZE / 2.0
	return (screen_position - size / 2.0 - _pan) / _zoom + map_center


func _select_nearest(screen_position: Vector2) -> void:
	if screen_position.x > size.x - PANEL_WIDTH - MARGIN * 2.0:
		return

	for location in WorldLocations.LOCATIONS:
		var pos: Vector2 = location["position"]
		if _map_to_screen(pos).distance_to(screen_position) < 17.0:
			_selected_id = location["id"]
			_update_details()
			queue_redraw()
			return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("171e23"))

	_draw_map_texture()
	_draw_routes()
	_draw_markers()


func _draw_map_texture() -> void:
	var texture_size: Vector2 = Vector2(MAP_TEXTURE.get_width(), MAP_TEXTURE.get_height())

	draw_set_transform(
		_map_to_screen(Vector2.ZERO),
		0.0,
		Vector2(_zoom, _zoom)
	)

	draw_texture(MAP_TEXTURE, Vector2.ZERO)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_routes() -> void:
	for route in WorldLocations.ROUTES:
		var a: Dictionary = _find_location(route[0])
		var b: Dictionary = _find_location(route[1])

		if not a.is_empty() and not b.is_empty():
			var a_pos: Vector2 = _map_to_screen(a["position"])
			var b_pos: Vector2 = _map_to_screen(b["position"])
			draw_dashed_line(a_pos, b_pos, Color(0.95, 0.88, 0.68, 0.75), 2.0, 7.0)


func _draw_markers() -> void:
	var font: Font = ThemeDB.fallback_font

	for location in WorldLocations.LOCATIONS:
		var marker_position: Vector2 = _map_to_screen(location["position"])
		var known: bool = _discovered.get(location["id"], false)
		var is_selected: bool = _selected_id == location["id"]

		draw_circle(
			marker_position,
			SELECTED_MARKER_RADIUS if is_selected else MARKER_RADIUS,
			Color("f2d38d") if known else Color("7b8183")
		)

		draw_arc(
			marker_position,
			15.0 if is_selected else 11.0,
			0.0,
			TAU,
			24,
			Color("f6e1ae", 0.8),
			1.2
		)

		var label_text: String = location["name"] if known else "?"
		draw_string(
			font,
			marker_position + Vector2(14, -13),
			label_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			17,
			Color("f1e5cb") if known else Color("989b94")
		)


func _find_location(location_id: String) -> Dictionary:
	for location in WorldLocations.LOCATIONS:
		if location["id"] == location_id:
			return location
	return {}
