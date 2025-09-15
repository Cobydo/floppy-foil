extends Node

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5
@onready var cpu_particles_2d: CPUParticles2D = $"../CPUParticles2D"

var character: CharacterBody2D
var is_dashing: bool = false
var facing_dir: Vector2 = Vector2.RIGHT

var dash_time: float = 0.0
var cooldown_time: float = 0.0

func _ready() -> void:
	character = get_parent() as CharacterBody2D
	assert(character, "Dash must be a child of CharacterBody2D!")

func _physics_process(delta: float) -> void:
	if cooldown_time > 0.0:
		cooldown_time -= delta

	if is_dashing:
		_process_dash(delta)
	else:
		_check_start_dash()

func _check_start_dash() -> void:
	# Look at current input
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Update facing if moving
	if input_dir != Vector2.ZERO:
		facing_dir = input_dir.normalized()

	# Dash input
	if Input.is_action_just_pressed("dash") and cooldown_time <= 0.0:
		cpu_particles_2d.emitting = true
		is_dashing = true
		dash_time = dash_duration
		cooldown_time = dash_cooldown

func _process_dash(delta: float) -> void:
	dash_time -= delta
	character.velocity = facing_dir * dash_speed
	character.move_and_slide()
	cpu_particles_2d.emitting = false

	if dash_time <= 0.0:
		is_dashing = false
