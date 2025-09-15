extends Sprite2D


@onready var player : Player = get_owner()

var start_offset : Vector2

func _ready() -> void:
	start_offset = position


func _process(delta: float) -> void:
	if !player.velocity:
		self.global_position = floor(player.global_position + start_offset) + Vector2(0.1, 0.1)
