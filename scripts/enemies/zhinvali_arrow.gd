extends Area2D

## Arrow fired by a Zhinvali archer. It can be blocked by Xizane's shield and
## cut out of the air by the Mountain Blade.

@export var speed: float = 610.0
@export var projectile_gravity: float = 105.0
@export var damage: int = 11
@export var poise_damage: float = 18.0
@export var lifetime: float = 4.0

var velocity: Vector2 = Vector2.RIGHT * 610.0
var _owner_enemy: Node
var _dead: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	monitoring = true
	monitorable = true
	add_to_group("zhinvali_enemy_projectile")

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(31.0, 7.0)
	collision.shape = shape
	add_child(collision)

	body_entered.connect(_on_body_entered)
	queue_redraw()


func setup(direction: Vector2, owner_enemy: Node, shot_damage: int = 11) -> void:
	_owner_enemy = owner_enemy
	damage = shot_damage
	var safe_direction := Vector2.RIGHT
	if direction.length() > 0.001:
		safe_direction = direction.normalized()
	velocity = safe_direction * speed
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	velocity.y += projectile_gravity * delta
	global_position += velocity * delta
	rotation = velocity.angle()


func _on_body_entered(body: Node2D) -> void:
	if _dead or body == _owner_enemy:
		return

	if body.is_in_group("player"):
		_dead = true
		monitoring = false
		if body.has_method("receive_enemy_hit"):
			var attack_from: Vector2 = global_position - velocity.normalized() * 72.0
			body.call("receive_enemy_hit", damage, attack_from, poise_damage)
		queue_free()
		return

	if body.has_method("take_hit"):
		return

	_dead = true
	queue_free()


func take_hit(_amount: int, knockback: Vector2, _poise_damage: float = 0.0) -> void:
	if _dead:
		return
	_dead = true
	monitoring = false
	velocity = knockback * 0.45
	var tween := create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.16)
	tween.parallel().tween_property(self, "position", position + velocity * 0.08, 0.16)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_line(Vector2(-19.0, 0.0), Vector2(13.0, 0.0), Color("#d7c6a2"), 2.2)
	draw_colored_polygon(PackedVector2Array([
		Vector2(14.0, 0.0), Vector2(5.0, -4.5), Vector2(5.0, 4.5)
	]), Color("#908b82"))
	draw_line(Vector2(-17.0, 0.0), Vector2(-24.0, -5.0), Color("#80694d"), 2.0)
	draw_line(Vector2(-17.0, 0.0), Vector2(-24.0, 5.0), Color("#80694d"), 2.0)
