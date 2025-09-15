extends Node

##########################################################
# This is the player's movement controller.
# Instead of placing all of the movement stuff inside
# of the player, we move the code to a separate component
##########################################################

@export_group("Speed Values")
@export var max_speed := 100.0
@export var acceleration_time := 0.1

@export var function : Callable

@onready var player : Player = get_owner()


func _ready():
	player.test_signal.connect(on_test_signal)


func on_test_signal():
	print("Guy listening to signal says hi!")


func _physics_process(delta):
	if !player.alive:
		return
	
	# Read the player's current velocity
	var velocity = player.velocity
	
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var target_speed := max_speed
	
	
	# Apply any changes to velocity
	velocity = velocity.move_toward(input_direction*target_speed, (1.0 / acceleration_time) * delta * target_speed)
	
	if input_direction.y && sign(input_direction.y) != sign(velocity.y):
		velocity.y *= 0.75 
	
	if input_direction.x && sign(input_direction.x) != sign(velocity.x):
		velocity.x *= 0.75
	
	# Reassign velocity and move the player
	player.velocity = velocity
	player.move_and_slide()
