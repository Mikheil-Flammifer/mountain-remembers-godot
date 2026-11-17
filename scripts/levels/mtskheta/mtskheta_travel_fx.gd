extends CanvasLayer
## Lightweight, code-generated UI for Mtskheta district travel.
## No art, fonts, or scene files required.

const AREA_NAMES: Dictionary = {
	"mtskheta.tscn": "MTSKHETA · OLD TOWN",
	"market.tscn": "MTSKHETA · MARKET",
	"streets.tscn": "MTSKHETA · STREETS",
	"cathedral_precinct.tscn": "SVETITSKHOVELI · CATHEDRAL",
	"terraces.tscn": "MTSKHETA · TERRACES",
	"north_road.tscn": "THE NORTHERN ROAD",
}

var _curtain: ColorRect
var _area_title: Label
var _curtain_tween: Tween
var _title_tween: Tween


func _ready() -> void:
	layer = 100
	_build_ui()
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_show_initial_area")


func _build_ui() -> void:
	_curtain = ColorRect.new()
	_curtain.name = "TransitionCurtain"
	_curtain.color = Color(0.035, 0.042, 0.055, 1.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.modulate.a = 0.0
	add_child(_curtain)

	_area_title = Label.new()
	_area_title.name = "AreaTitle"
	_area_title.anchor_left = 0.0
	_area_title.anchor_right = 1.0
	_area_title.offset_left = 20.0
	_area_title.offset_right = -20.0
	_area_title.offset_top = 52.0
	_area_title.offset_bottom = 103.0
	_area_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_area_title.add_theme_font_size_override("font_size", 26)
	_area_title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.72))
	_area_title.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.05))
	_area_title.add_theme_constant_override("outline_size", 6)
	_area_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area_title.modulate.a = 0.0
	add_child(_area_title)


func fade_out() -> void:
	if _curtain_tween != null and _curtain_tween.is_running():
		_curtain_tween.kill()
	_curtain_tween = create_tween()
	_curtain_tween.tween_property(_curtain, "modulate:a", 1.0, 0.24)
	await _curtain_tween.finished


func fade_in() -> void:
	if _curtain_tween != null and _curtain_tween.is_running():
		_curtain_tween.kill()
	_curtain_tween = create_tween()
	_curtain_tween.tween_property(_curtain, "modulate:a", 0.0, 0.28)
	await _curtain_tween.finished


func _on_scene_changed(scene_root: Node) -> void:
	var filename: String = scene_root.scene_file_path.get_file()
	if not AREA_NAMES.has(filename):
		return
	fade_in()
	_show_title(str(AREA_NAMES[filename]))


func _show_initial_area() -> void:
	var current: Node = get_tree().current_scene
	if current == null:
		return
	var filename: String = current.scene_file_path.get_file()
	if AREA_NAMES.has(filename):
		_show_title(str(AREA_NAMES[filename]))


func _show_title(title_text: String) -> void:
	if _title_tween != null and _title_tween.is_running():
		_title_tween.kill()
	_area_title.text = title_text
	_area_title.modulate.a = 0.0
	_title_tween = create_tween()
	_title_tween.tween_property(_area_title, "modulate:a", 1.0, 0.35)
	_title_tween.tween_interval(1.65)
	_title_tween.tween_property(_area_title, "modulate:a", 0.0, 0.55)
