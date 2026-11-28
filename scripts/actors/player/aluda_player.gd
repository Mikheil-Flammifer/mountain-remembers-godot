extends CharacterBody2D
## Aluda owns movement and combat input. Visuals receive presentation state.

@export var run_speed: float = 225.0
@export var acceleration: float = 1600.0
@export var jump_velocity: float = -440.0
@export var gravity: float = 1150.0
@export var attack_duration: float = 0.42

@onready var visual_slot: ActorVisualSlot = $VisualSlot

var facing: float = 1.0
var _state := ActorVisualState.new()
var _attack_remaining: float = 0.0
var _blocking: bool = false


func _physics_process(delta: float) -> void:
	_attack_remaining = maxf(0.0, _attack_remaining - delta)
	_blocking = Input.is_action_pressed("shield") and _attack_remaining <= 0.0
	if Input.is_action_just_pressed("attack") and not _blocking and _attack_remaining <= 0.0:
		_attack_remaining = attack_duration
	var direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction):
		facing = signf(direction)
	var speed := run_speed * (0.45 if _blocking else 1.0)
	velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	move_and_slide()


func _process(delta: float) -> void:
	_state.facing_direction = facing
	_state.velocity = velocity
	_state.run_speed = run_speed
	_state.is_grounded = is_on_floor()
	_state.is_attacking = _attack_remaining > 0.0
	_state.attack_progress = 1.0 - _attack_remaining / maxf(attack_duration, 0.001)
	_state.is_blocking = _blocking
	visual_slot.update_visual(_state, delta)
