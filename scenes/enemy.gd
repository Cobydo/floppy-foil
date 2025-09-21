extends CharacterBody2D

@export var speed: float = 100
@export var headbutt_speed: float = 400
@export var headbutt_range: float = 100
@export var headbutt_cooldown: float = 5
@export var headbutt_duration: float = 0.5

var target: Node2D
var headbutt_timer: float = 0.0
var cooldown_timer: float = 0.0
var headbutting: bool = false
var headbutt_dir: Vector2 = Vector2.ZERO

func _ready():
	# Assign the player as the target
	target = get_tree().get_current_scene().get_node("Player")

func _physics_process(delta):
	if not target:
		return

	var to_player = target.global_position - global_position
	var distance_to_player = to_player.length()

	# Update cooldown timer
	cooldown_timer += delta

	# Start headbutt if cooldown is ready and close enough
	if not headbutting and cooldown_timer >= headbutt_cooldown and distance_to_player < headbutt_range:
		headbutting = true
		headbutt_timer = headbutt_duration
		cooldown_timer = 0.0
		headbutt_dir = to_player.normalized()
		print("Charging headbutt!")

	if headbutting:
		# Dash toward player
		velocity = headbutt_dir * headbutt_speed
		headbutt_timer -= delta
		if headbutt_timer <= 0:
			headbutting = false
			velocity = Vector2.ZERO
			print("Headbutt finished!")
	else:
		# Normal movement toward player
		velocity = to_player.normalized() * speed

	move_and_slide()

	# Rotate enemy toward movement direction
	if velocity.length() > 0:
		rotation = velocity.angle()
