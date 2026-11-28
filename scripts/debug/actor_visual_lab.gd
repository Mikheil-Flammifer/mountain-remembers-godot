extends Control
## Preview Xizane's existing visual without starting a story level.

const APPEARANCE := preload("res://resources/visuals/actors/xizane/default_appearance.tres")
const MODES: Array[String] = ["Idle", "Run", "Jump", "Fall", "Dash", "Attack 1", "Attack 2", "Attack up", "Attack down", "Block", "Rest", "Climb"]

@onready var visual_slot: ActorVisualSlot = $Stage/VisualSlot
@onready var mode_picker: OptionButton = $Panel/Margin/Controls/Mode
@onready var facing_picker: OptionButton = $Panel/Margin/Controls/Facing
@onready var speed_slider: HSlider = $Panel/Margin/Controls/Speed
@onready var speed_label: Label = $Panel/Margin/Controls/SpeedLabel
@onready var animation_label: Label = $Panel/Margin/Controls/Animation

var _state := ActorVisualState.new()
var _clock: float = 0.0


func _ready() -> void:
	for mode in MODES:
		mode_picker.add_item(mode)
	facing_picker.add_item("Right")
	facing_picker.add_item("Left")
	mode_picker.item_selected.connect(_select_mode)
	$Panel/Margin/Controls/Flash.pressed.connect(visual_slot.flash_damage)
	visual_slot.set_appearance(APPEARANCE)
	$Stage.resized.connect(_position_visual)
	_position_visual()


func _position_visual() -> void:
	visual_slot.position = $Stage.size * Vector2(0.60, 0.75)


func _select_mode(_index: int) -> void:
	_clock = 0.0


func _process(delta: float) -> void:
	var preview_delta := delta * speed_slider.value
	_clock += preview_delta
	var mode := mode_picker.selected
	_state.velocity = Vector2.ZERO
	_state.run_speed = 315.0
	_state.facing_direction = 1.0 if facing_picker.selected == 0 else -1.0
	_state.is_grounded = mode not in [2, 3, 11]
	_state.is_dashing = mode == 4
	_state.is_attacking = mode >= 5 and mode <= 8
	_state.is_blocking = mode == 9
	_state.is_resting = mode == 10
	_state.is_climbing = mode == 11
	_state.climb_phase = _clock * 8.0
	_state.combo_step = 1 if mode == 6 else 0
	_state.attack_direction = "up" if mode == 7 else ("down" if mode == 8 else "forward")
	_state.attack_progress = fmod(_clock / 0.55, 1.0)
	if mode == 1:
		_state.velocity.x = 315.0 * _state.facing_direction
	elif mode == 2:
		_state.velocity.y = -300.0
	elif mode == 3:
		_state.velocity.y = 300.0
	visual_slot.update_visual(_state, preview_delta)
	speed_label.text = "Preview speed: %.2fx" % speed_slider.value
	animation_label.text = "Visual state: %s" % visual_slot.get_current_animation()
