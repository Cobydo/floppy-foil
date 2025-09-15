class_name Player
extends CharacterBody2D

@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var dash_component = $DashComponent
var facing_direction = Vector2.DOWN
var aim_position : Vector2 = Vector2(1, 0)

signal damaged

signal test_signal


var alive := true
var invincible := false
