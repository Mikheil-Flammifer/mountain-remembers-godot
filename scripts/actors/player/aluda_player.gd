extends CharacterBody2D
## Aluda owns movement and combat input. Visuals receive presentation state.

@export var run_speed: float = 225.0
@export var acceleration: float = 1600.0
@export var jump_velocity: float = -440.0
@export var gravity: float = 1150.0
@export var attack_duration: float = 0.42
@export_group("Riding")
@export var ride_speed: float = 470.0
@export var ride_acceleration: float = 820.0
@export var ride_jump_velocity: float = -470.0

@onready var visual_slot: ActorVisualSlot = $VisualSlot

var facing: float = 1.0
var _state := ActorVisualState.new()
var _attack_remaining: float = 0.0
var _blocking: bool = false
var mounted: bool = false
var horse: HorseVisual


## Swing up into the saddle: the horse becomes part of Aluda until dismount.
func mount(target: HorseVisual) -> bool:
	if mounted or target == null:
		return false
	horse = target
	if horse.get_parent() != null:
		horse.get_parent().remove_child(horse)
	add_child(horse)
	move_child(horse, 0)
	horse.position = Vector2.ZERO
	horse.facing = facing
	mounted = true
	return true


## Step down; the horse stays where Aluda left it, in the given parent.
func dismount(world: Node) -> HorseVisual:
	if not mounted:
		return null
	var left := horse
	var spot := global_position
	remove_child(left)
	world.add_child(left)
	left.global_position = spot
	left.update_gait(0.0, facing, false, 0.0)
	mounted = false
	horse = null
	velocity.x = 0.0
	visual_slot.position = Vector2.ZERO
	return left


func _physics_process(delta: float) -> void:
	_attack_remaining = maxf(0.0, _attack_remaining - delta)
	_blocking = Input.is_action_pressed("shield") and _attack_remaining <= 0.0
	if Input.is_action_just_pressed("attack") and not _blocking and _attack_remaining <= 0.0:
		_attack_remaining = attack_duration
	var direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction):
		facing = signf(direction)
	var speed := run_speed * (0.45 if _blocking else 1.0)
	var accel := acceleration
	if mounted:
		speed = ride_speed * (0.6 if _blocking else 1.0)
		accel = ride_acceleration
	velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = ride_jump_velocity if mounted else jump_velocity
	move_and_slide()


func _process(delta: float) -> void:
	_state.facing_direction = facing
	_state.velocity = velocity
	_state.run_speed = ride_speed if mounted else run_speed
	_state.is_mounted = mounted
	_state.ride_bounce = 0.0
	if mounted and horse != null:
		horse.update_gait(absf(velocity.x) / ride_speed, facing, not is_on_floor(), delta)
		visual_slot.position = horse.seat_offset - Vector2(0.0, -31.0)
		_state.ride_bounce = (horse.seat_offset.y - HorseVisual.SEAT.y) * 0.35
	_state.is_grounded = is_on_floor()
	_state.is_attacking = _attack_remaining > 0.0
	_state.attack_progress = 1.0 - _attack_remaining / maxf(attack_duration, 0.001)
	_state.is_blocking = _blocking
	visual_slot.update_visual(_state, delta)
