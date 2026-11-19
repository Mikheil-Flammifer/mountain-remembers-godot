extends Node2D

## Upper town: hills, stone retaining walls and wood/stone platforms.
## Real platform colliders are in terraces.tscn.
## Also draws visible thorn traps for the damaging trap nodes.

var _trap_positions: Array[Vector2] = []

func _ready() -> void:
	_collect_trap_positions()
	queue_redraw()


func _collect_trap_positions() -> void:
	_trap_positions.clear()

	# Looks for nodes named like Trap1 / ThornTrap / SpikeTrap
	# or any node added to the "terrace_trap" group.
	for node: Node in get_children():
		if not node is Node2D:
			continue

		var n: Node2D = node as Node2D
		var lower_name: String = n.name.to_lower()

		if n.is_in_group("terrace_trap") or "trap" in lower_name:
			_trap_positions.append(n.position)


func _draw() -> void:
	draw_rect(Rect2(0, -500, 2400, 1250), Color("#d5bd9c"))

	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 500), Vector2(290, 210), Vector2(520, 440),
		Vector2(980, 150), Vector2(1290, 420), Vector2(1680, 175),
		Vector2(2100, 390), Vector2(2400, 210),
		Vector2(2400, 650), Vector2(0, 650)
	]), Color("#9a896d"))

	draw_rect(Rect2(0, 650, 2400, 170), Color("#826c53"))

	for x: float in [270.0, 750.0, 1400.0, 1940.0]:
		draw_rect(Rect2(x, 455, 310, 195), Color("#a38a6d"))
		for y: float in [495.0, 540.0, 590.0]:
			draw_line(Vector2(x, y), Vector2(x + 310, y), Color("#59594f"), 1)

	# Raised terraces match the platform collision nodes in the scene.
	for pos: Vector2 in [Vector2(600, 548), Vector2(1100, 495), Vector2(1590, 550)]:
		draw_rect(Rect2(pos, Vector2(210, 18)), Color("#b9a184"))
		draw_rect(Rect2(pos.x, pos.y, 210, 4), Color("#e0c5a0"))

	_draw_traps()


func _draw_traps() -> void:
	for pos: Vector2 in _trap_positions:
		_draw_thorn_patch(pos)


func _draw_thorn_patch(center: Vector2) -> void:
	# Adjust this vertical offset if your trap hurtbox sits slightly
	# above or below the ground.
	var base_y: float = center.y + 18.0
	var width: float = 92.0

	# Dark brush / root base
	draw_rect(
		Rect2(center.x - width * 0.5, base_y - 10.0, width, 10.0),
		Color("#4b4032")
	)

	# Spikes / thorns
	var spike_count: int = 7
	for i in range(spike_count):
		var t: float = float(i) / float(spike_count - 1)
		var x: float = lerpf(center.x - width * 0.42, center.x + width * 0.42, t)

		var height: float = 18.0
		if i % 2 == 0:
			height = 28.0

		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 7.0, base_y),
			Vector2(x, base_y - height),
			Vector2(x + 7.0, base_y)
		]), Color("#2f2f2a"))

		# Highlight on the spike
		draw_line(
			Vector2(x, base_y - height + 4.0),
			Vector2(x, base_y - 2.0),
			Color("#7e7767"),
			1.2
		)

	# Small thorny branches to make it more obvious
	draw_line(
		Vector2(center.x - 26.0, base_y - 8.0),
		Vector2(center.x - 10.0, base_y - 18.0),
		Color("#3c342b"),
		2.0
	)
	draw_line(
		Vector2(center.x + 22.0, base_y - 7.0),
		Vector2(center.x + 8.0, base_y - 17.0),
		Color("#3c342b"),
		2.0
	)