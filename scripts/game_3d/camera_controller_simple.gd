extends Camera3D

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0, 8, 12)  # Camera position relative to player
@export var look_ahead_offset: Vector3 = Vector3(0, 2, 0)  # Where camera looks relative to player
@export var position_smoothness: float = 8.0  # How fast camera follows position
@export var rotation_smoothness: float = 12.0  # How fast camera follows rotation
@export var max_follow_distance: float = 25.0  # Maximum distance camera can be from player
@export var min_follow_distance: float = 8.0   # Minimum distance camera can be from player
@export var dynamic_offset: bool = true  # Enable dynamic camera positioning based on movement

var target_node: Node3D
var current_velocity: Vector3 = Vector3.ZERO
var last_target_position: Vector3 = Vector3.ZERO

func _ready():
	# Wait for scene to be fully ready
	call_deferred("setup_target")

func setup_target():
	if target_path:
		target_node = get_node_or_null(target_path)
		print("Camera target path: ", target_path, " Found: ", target_node != null)
	
	# If the configured path didn't work, try alternative paths
	if not target_node:
		# Try from the scene root
		var scene_root = get_tree().current_scene
		if scene_root:
			target_node = scene_root.get_node_or_null("Players/Player1")
			print("Camera trying scene root path: Players/Player1, Found: ", target_node != null)
	
	if not target_node:
		print("Camera target not found")
		return
	else:
		print("Camera successfully connected to target: ", target_node.name)

func _process(delta):
	if not target_node:
		return
	
	# Calculate target velocity for prediction
	var target_position = target_node.global_position
	current_velocity = (target_position - last_target_position) / delta
	last_target_position = target_position
	
	# Calculate dynamic offset based on player movement
	var dynamic_follow_offset = follow_offset
	if dynamic_offset and current_velocity.length() > 0.5:
		# Push camera back when player is moving fast
		var movement_direction = Vector3(current_velocity.x, 0, current_velocity.z).normalized()
		var speed_factor = min(current_velocity.length() / 10.0, 1.0)
		dynamic_follow_offset += movement_direction * -3.0 * speed_factor
		dynamic_follow_offset.y += speed_factor * 2.0  # Raise camera when moving fast
	
	# Calculate desired camera position
	var desired_position = target_position + dynamic_follow_offset
	
	# Smooth camera movement
	global_position = global_position.lerp(desired_position, position_smoothness * delta)
	
	# Calculate look-at position with prediction
	var look_target = target_position + look_ahead_offset
	if current_velocity.length() > 1.0:
		# Look ahead in the direction of movement
		var movement_prediction = Vector3(current_velocity.x, 0, current_velocity.z).normalized() * 3.0
		look_target += movement_prediction
	
	# Smooth camera rotation
	var current_transform = global_transform
	var target_transform = current_transform.looking_at(look_target, Vector3.UP)
	
	# Interpolate rotation
	global_transform = global_transform.interpolate_with(target_transform, rotation_smoothness * delta)
	
	# Maintain distance constraints
	var distance_to_target = global_position.distance_to(target_position)
	if distance_to_target > max_follow_distance:
		var direction = (target_position - global_position).normalized()
		global_position = target_position - direction * max_follow_distance
	elif distance_to_target < min_follow_distance:
		var direction = (target_position - global_position).normalized()
		global_position = target_position - direction * min_follow_distance

func _unhandled_input(event):
	# Camera zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			follow_offset = follow_offset * 0.9  # Zoom in
			follow_offset = follow_offset.limit_length(min_follow_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			follow_offset = follow_offset * 1.1  # Zoom out
			follow_offset = follow_offset.limit_length(max_follow_distance)
	
	# Reset camera with middle mouse or C key
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_C and event.pressed):
		_reset_camera_position()

func _reset_camera_position():
	follow_offset = Vector3(0, 8, 12)
	position_smoothness = 8.0
	rotation_smoothness = 12.0
	print("Camera position reset")
