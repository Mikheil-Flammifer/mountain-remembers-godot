extends StaticBody2D
## One-way ledge: starts to crack on touch; rebuilds after a delay.
@export var recovery_seconds: float = 3.4
@export var break_delay: float = 0.6
var _phase: String = "solid"
var _timer: float = 0.0
var _shape: CollisionShape2D
var _trigger: Area2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	_shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(150, 18)
	_shape.shape = rectangle
	_shape.one_way_collision = true
	add_child(_shape)
	_trigger = Area2D.new()
	_trigger.collision_layer = 0
	_trigger.collision_mask = 1
	var col := CollisionShape2D.new()
	var detector := RectangleShape2D.new()
	detector.size = Vector2(145, 34)
	col.shape = detector
	col.position = Vector2(0, -16)
	_trigger.add_child(col)
	add_child(_trigger)
	_trigger.body_entered.connect(_on_touch)

func _on_touch(body: Node2D) -> void:
	if _phase == "solid" and body.is_in_group("player"):
		_phase = "cracking"
		_timer = break_delay

func _physics_process(delta: float) -> void:
	if _phase == "solid":
		return
	_timer -= delta
	if _phase == "cracking" and _timer <= 0.0:
		_phase = "fallen"
		_timer = recovery_seconds
		_shape.set_deferred("disabled", true)
	elif _phase == "fallen" and _timer <= 0.0:
		_phase = "solid"
		_shape.set_deferred("disabled", false)
	queue_redraw()

func _draw() -> void:
	if _phase == "fallen":
		return
	var stone := Color("#bd8b68") if _phase == "cracking" else Color("#8d8770")
	draw_rect(Rect2(-75,-9,150,18), stone)
	draw_rect(Rect2(-75,-9,150,4), Color("#c3b08c"))
	for i in range(5):
		var x: float = -61.0 + float(i) * 29.0
		draw_line(Vector2(x,-5),Vector2(x + 8,7),Color("#544f45"),2.5 if _phase == "cracking" else 1.2)
