extends Node2D

@onready var line: Line2D = $BladeLine  # The Line2D node representing the blade

# --- Geometry ---
@export var segment_count: int = 14          # Number of segments in the blade (more segments = smoother/floppier)
@export var min_length: float = 100.0        # Minimum blade length (prevents collapsing)
@export var max_length: float = 160.0        # Maximum blade length (prevents over-stretching)
@export var length_adjust_speed: float = 8.0 # How fast the blade smoothly adjusts length toward the mouse

# --- Solver / feel ---
@export var constraint_iterations: int = 10      # Number of passes to enforce segment lengths (higher = stiffer blade)
@export var post_constraint_iterations: int = 3  # Extra passes after smoothing to ensure lengths remain accurate
@export var smoothing_strength: float = 0.14    # How much Laplacian smoothing is applied (0 = none, 1 = max smooth)
@export var verlet_damping: float = 0.04        # Damping applied to segment velocities (higher = less wobble)
@export var tip_strength: float = 1800.0        # Acceleration applied to the tip when springy (higher = snappier tip)

# --- Tip behavior ---
@export var springy_tip: bool = true  # true = tip lags, false = hard-locked

# --- Visuals ---
@export var line_width: float = 3.0

# --- Internal state ---
var pos: Array[Vector2] = []
var prev_pos: Array[Vector2] = []
var base_pos: Vector2 = Vector2.ZERO
var current_length: float = 140.0
var rest_length: float = 10.0

func _ready() -> void:
	segment_count = max(3, segment_count)
	current_length = clamp((min_length + max_length) * 0.5, min_length, max_length)
	rest_length = current_length / float(segment_count - 1)

	pos.resize(segment_count)
	prev_pos.resize(segment_count)

	base_pos = global_position
	for i in range(segment_count):
		var p: Vector2 = base_pos + Vector2(rest_length * i, 0)
		pos[i] = p
		prev_pos[i] = p

	line.width = line_width
	line.default_color = Color.WHITE

func _process(delta: float) -> void:
	base_pos = global_position

	# --- Compute desired blade length ---
	var raw_target: Vector2 = get_global_mouse_position()
	var dir: Vector2 = raw_target - base_pos
	var dist: float = dir.length()
	var desired_length: float = clamp(dist, min_length, max_length)
	var t: float = clamp(length_adjust_speed * delta, 0.0, 1.0)
	current_length = lerp(current_length, desired_length, t)
	rest_length = current_length / float(segment_count - 1)

	var clamp_target: Vector2
	if dist > 0.001:
		clamp_target = base_pos + dir.normalized() * current_length
	else:
		clamp_target = base_pos + Vector2.RIGHT * current_length

	# --- Verlet integration ---
	for i in range(segment_count):
		var p: Vector2 = pos[i]
		var pv: Vector2 = prev_pos[i]
		var vel: Vector2 = p - pv
		vel *= (1.0 - verlet_damping)
		prev_pos[i] = p
		pos[i] = p + vel

	# --- Lock base ---
	pos[0] = base_pos
	prev_pos[0] = base_pos

	# --- Tip behavior toggle ---
	if springy_tip:
		# springy tip
		var tip_vel: Vector2 = pos[segment_count - 1] - prev_pos[segment_count - 1]
		var tip_acc: Vector2 = (clamp_target - pos[segment_count - 1]) * tip_strength
		var new_tip: Vector2 = pos[segment_count - 1] + tip_vel + tip_acc * (delta * delta)
		prev_pos[segment_count - 1] = pos[segment_count - 1]
		pos[segment_count - 1] = new_tip
	else:
		# hard-locked tip
		pos[segment_count - 1] = clamp_target
		prev_pos[segment_count - 1] = clamp_target

	# --- Constraint relaxation ---
	for _iter in range(constraint_iterations):
		for i in range(segment_count - 1):
			var a: Vector2 = pos[i]
			var b: Vector2 = pos[i + 1]
			var delta_vec: Vector2 = b - a
			var d: float = delta_vec.length()
			if d == 0.0:
				continue
			var error: float = (d - rest_length) / d
			var correction: Vector2 = delta_vec * 0.5 * error
			var inv_a: float = 0.0 if i == 0 else 1.0
			var inv_b: float = 0.0 if (i + 1) == segment_count - 1 else 1.0
			var sum_inv: float = inv_a + inv_b
			if sum_inv == 0.0:
				continue
			pos[i] = pos[i] + correction * (inv_a / sum_inv)
			pos[i + 1] = pos[i + 1] - correction * (inv_b / sum_inv)

	# --- Smoothing ---
	if smoothing_strength > 0.0:
		var smoothed: Array[Vector2] = []
		smoothed.resize(segment_count)
		smoothed[0] = pos[0]
		smoothed[segment_count - 1] = pos[segment_count - 1]
		for i in range(1, segment_count - 1):
			var lap: Vector2 = (pos[i - 1] + pos[i + 1]) * 0.5
			smoothed[i] = pos[i].lerp(lap, smoothing_strength)
		for i in range(1, segment_count - 1):
			pos[i] = smoothed[i]

	# --- Post constraint after smoothing ---
	for _iter in range(post_constraint_iterations):
		for i in range(segment_count - 1):
			var a2: Vector2 = pos[i]
			var b2: Vector2 = pos[i + 1]
			var delta_vec2: Vector2 = b2 - a2
			var d2: float = delta_vec2.length()
			if d2 == 0.0:
				continue
			var error2: float = (d2 - rest_length) / d2
			var correction2: Vector2 = delta_vec2 * 0.5 * error2
			var inv_a2: float = 0.0 if i == 0 else 1.0
			var inv_b2: float = 0.0 if (i + 1) == segment_count - 1 else 1.0
			var sum_inv2: float = inv_a2 + inv_b2
			if sum_inv2 == 0.0:
				continue
			pos[i] = pos[i] + correction2 * (inv_a2 / sum_inv2)
			pos[i + 1] = pos[i + 1] - correction2 * (inv_b2 / sum_inv2)

	# --- Step 7: update Line2D ---
	var packed: PackedVector2Array = PackedVector2Array()
	for i in range(segment_count):
		packed.append(to_local(pos[i]))  # convert from global to local
	line.points = packed
