extends Camera2D

# Reference to the player node
@export var player: Node2D  # The player node to follow - drag your player here

# Camera positioning settings
@export var fixed_position_mode: bool = true  # If true, camera stays near fixed point; if false, follows player
@export var fixed_camera_position: Vector2 = Vector2.ZERO  # Fixed world position for camera center (set in editor or code)

# Camera smoothing and movement settings
@export var follow_speed: float = 3.0  # How quickly camera catches up to target (higher = snappier, lower = more lag)
@export var velocity_offset_strength: float = 0.3  # How much camera moves based on player velocity (0 = no movement, 1 = strong movement)
@export var max_velocity_offset: float = 5.0  # Maximum distance camera can move from center in pixels (for 320x180: 3-8px recommended)

# Camera tilting settings (left/right lean when moving sideways)
@export var tilt_strength: float = 15.0  # Maximum tilt angle in degrees (higher = more dramatic lean)
@export var tilt_speed: float = 5.0  # How fast the camera tilts when starting to move (higher = more responsive)
@export var tilt_reset_speed: float = 3.0  # How fast camera levels out when stopping (higher = quicker reset)

# Camera rotation settings (full rotation following movement direction)
@export var enable_rotation: bool = true  # Toggle rotation effect on/off
@export var rotation_strength: float = 30.0  # Maximum rotation angle in degrees (higher = more dramatic turns)
@export var rotation_speed: float = 2.0  # How fast camera rotates to match movement (higher = more responsive)
@export var rotation_reset_speed: float = 2.5  # How fast camera straightens when stopping (higher = quicker reset)
@export var rotation_velocity_threshold: float = 100.0  # Minimum speed needed to trigger rotation (prevents jitter at low speeds)

# Internal variables (don't modify these directly)
var target_position: Vector2  # Where the camera wants to move to
var target_tilt: float = 0.0  # Target tilt angle for left/right lean
var target_rotation: float = 0.0  # Target rotation angle for directional rotation
var current_tilt: float = 0.0  # Current tilt angle (smoothly interpolated)
var current_rotation: float = 0.0  # Current rotation angle (smoothly interpolated)
var player_velocity: Vector2 = Vector2.ZERO  # Smoothed player velocity vector
var velocity_smoothing: float = 8.0  # How quickly velocity changes are smoothed (higher = more responsive)
var movement_direction: Vector2 = Vector2.ZERO  # Normalized direction of movement (for rotation calculation)

func _ready():
	# Get player reference if not assigned
	
	if player == null:
		print("Warning: Player not found! Please assign the player node or check the player_path.")
		return
	
	# Set camera position based on mode
	if fixed_position_mode:
		# Use fixed position (set to current position if not specified)
		if fixed_camera_position == Vector2.ZERO:
			fixed_camera_position = global_position
		print("Camera set to fixed position mode with center at: ", fixed_camera_position)
	else:
		# Set initial camera position to player position for follow mode
		global_position = player.global_position

func _process(delta):
	if player == null:
		return
	
	# Get player velocity (different methods depending on player type)
	var new_velocity = Vector2.ZERO
	if player.has_method("get_velocity"):
		new_velocity = player.get_velocity()
	elif player is CharacterBody2D:
		new_velocity = player.velocity
	elif player is RigidBody2D:
		new_velocity = player.linear_velocity
	
	# Smooth the velocity for less jittery camera movement
	player_velocity = player_velocity.lerp(new_velocity, velocity_smoothing * delta)
	
	# Update movement direction
	if player_velocity.length() > 10.0:
		movement_direction = movement_direction.lerp(player_velocity.normalized(), 5.0 * delta)
	
	update_camera_position(delta)
	update_camera_rotation_and_tilt(delta)

func update_camera_position(delta):
	if not fixed_position_mode:
		# Follow mode: Follow player position + velocity-based lookahead
		var velocity_offset = (player_velocity / 500.0) * velocity_offset_strength
		velocity_offset = velocity_offset.limit_length(max_velocity_offset)
		target_position = player.global_position + velocity_offset
		global_position = global_position.lerp(target_position, 0.8)
		return
	
	# Fixed mode: Move around the fixed center point based on player velocity
	var velocity_offset = (player_velocity / 500.0) * velocity_offset_strength
	velocity_offset = velocity_offset.limit_length(max_velocity_offset)
	
	# Calculate target as: fixed center + small velocity offset
	var new_target = fixed_camera_position + velocity_offset
	
	# Move camera to target position
	global_position = global_position.lerp(new_target, 0.8)

func update_camera_rotation_and_tilt(delta):
	var horizontal_velocity = player_velocity.x
	var velocity_magnitude = player_velocity.length()
	
	# === TILT CALCULATION (left/right lean based on horizontal movement) ===
	var velocity_factor = clamp(horizontal_velocity / 300.0, -1.0, 1.0)
	target_tilt = -velocity_factor * tilt_strength * (PI / 180.0)  # Convert to radians
	
	# Choose tilt interpolation speed
	var tilt_lerp_speed = tilt_speed if abs(horizontal_velocity) > 50.0 else tilt_reset_speed
	current_tilt = lerp_angle(current_tilt, target_tilt, tilt_lerp_speed * delta)
	
	# === ROTATION CALCULATION (camera follows movement direction) ===
	if enable_rotation and velocity_magnitude > rotation_velocity_threshold:
		# Calculate rotation based on movement direction
		var movement_angle = movement_direction.angle()
		
		# Apply rotation strength (convert degrees to radians)
		var rotation_factor = clamp(velocity_magnitude / 500.0, 0.0, 1.0)
		target_rotation = movement_angle * rotation_factor * (rotation_strength * PI / 180.0)
		
		# Limit extreme rotations
		var max_rotation_rad = rotation_strength * (PI / 180.0)
		target_rotation = clamp(target_rotation, -max_rotation_rad, max_rotation_rad)
		
		current_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
	else:
		# Reset rotation when moving slowly or rotation is disabled
		current_rotation = lerp_angle(current_rotation, 0.0, rotation_reset_speed * delta)
	
	# === APPLY COMBINED ROTATION ===
	# Combine tilt and rotation for the final camera rotation
	rotation = current_tilt + current_rotation

# Set fixed camera position (call this to change position during gameplay)
func set_fixed_position(new_position: Vector2):
	fixed_camera_position = new_position
	if fixed_position_mode:
		global_position = fixed_camera_position

# Toggle between fixed and follow modes
func set_fixed_mode(enabled: bool):
	fixed_position_mode = enabled
	if fixed_position_mode:
		global_position = fixed_camera_position
	print("Camera mode changed to: ", "Fixed with Movement" if enabled else "Follow Player")
func add_screen_shake(intensity: float, duration: float):
	var shake_tween = create_tween()
	var original_offset = offset
	
	shake_tween.tween_method(_shake_camera, intensity, 0.0, duration)
	shake_tween.tween_callback(func(): offset = original_offset)

func _shake_camera(intensity: float):
	offset = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)

# Optional: Smooth zoom functionality
func smooth_zoom_to(target_zoom: Vector2, duration: float = 1.0):
	var zoom_tween = create_tween()
	zoom_tween.tween_property(self, "zoom", target_zoom, duration)
	zoom_tween.set_trans(Tween.TRANS_QUART)
	zoom_tween.set_ease(Tween.EASE_OUT)

# Debug function to visualize camera behavior
func _draw():
	if Engine.is_editor_hint():
		return
	
	# Draw velocity vector (optional debug visualization)
	if player != null and player_velocity.length() > 10:
		var start_pos = to_local(player.global_position)
		var end_pos = start_pos + player_velocity * 0.1
		draw_line(start_pos, end_pos, Color.YELLOW, 2.0)
		draw_circle(end_pos, 4.0, Color.YELLOW)
