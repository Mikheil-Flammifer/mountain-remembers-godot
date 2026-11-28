extends Control
## Act menu. Act I is always open; every later act opens only after the act
## before it is finished. Starting an act hands it only the earlier choices it
## needs, so the acts stay separate.

const Progress = preload("res://scripts/systems/story/act_progress.gd")
const ROMAN := ["I", "II", "III", "IV", "V"]

var buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#101f2e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var title := Label.new()
	title.text = "ALUDA KETELAURI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#e9d8b5"))
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Choose an act. Finish an act to open the next."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("#b9ab8e"))
	box.add_child(sub)
	for act in range(1, Progress.ACT_COUNT + 1):
		var b := Button.new()
		b.name = "Act%d" % act
		b.custom_minimum_size = Vector2(460, 48)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(start_act.bind(act))
		box.add_child(b)
		buttons.append(b)
	refresh()
	if not buttons[0].disabled:
		buttons[0].grab_focus.call_deferred()


func refresh() -> void:
	for i in buttons.size():
		var act := i + 1
		var b := buttons[i]
		var label := "ACT %s  ·  %s" % [ROMAN[i], Progress.ACT_TITLES[i]]
		if not Progress.is_built(act):
			b.text = label + "   (not built yet)"
			b.disabled = true
		elif not Progress.is_unlocked(act):
			b.text = label + "   🔒 finish Act %s first" % ROMAN[i - 1]
			b.disabled = true
		else:
			b.text = label + ("   ✓" if Progress.is_complete(act) else "")
			b.disabled = false


## Returns false for a locked or unbuilt act; never opens one early.
func start_act(act: int) -> bool:
	if not Progress.is_unlocked(act) or not Progress.is_built(act):
		return false
	var tree := get_tree()
	for key in ["aluda_act_one_hand_choice", "aluda_act_two_dream_choice", "aluda_act_two_complete"]:
		if tree.has_meta(key):
			tree.remove_meta(key)
	if act >= 2:
		tree.set_meta("aluda_act_one_hand_choice", int(Progress.get_value(1, "hand_choice", 0)))
	if act >= 3:
		tree.set_meta("aluda_act_two_dream_choice", int(Progress.get_value(2, "dream_choice", 0)))
	tree.change_scene_to_file.call_deferred(Progress.ACT_SCENES[act])
	return true
