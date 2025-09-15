extends Node

@export var animation_tree : AnimationTree
@export var sprite : Sprite2D

@onready var player : Player = get_owner()


func _ready():
	# The animation tree is inactive while outside of gameplay.
	# This makes it easier to edit animations in the editor.
	animation_tree.active = true

var last_facing_direction := Vector2(0,-1)

func _physics_process(delta: float) -> void:
	if !player.alive:
		animation_tree.active = false
		return
	
	var idle = !player.velocity
	
	if !idle:
		last_facing_direction = player.velocity.normalized()
	animation_tree.set("parameters/Idle/BlendSpace1D/blend_position", last_facing_direction.x)
	animation_tree.set("parameters/Run/BlendSpace1D/blend_position",last_facing_direction.x)

	
