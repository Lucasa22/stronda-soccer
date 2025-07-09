extends Camera3D

@export var target_path: NodePath
@export var follow_offset: Vector3 = Vector3(0, 5, 8)  # Closer and lower for better view
@export var position_smoothness: float = 6.0  # Slower, more stable following
@export var rotation_smoothness: float = 4.0  # Much slower rotation
@export var max_follow_distance: float = 12.0
@export var min_follow_distance: float = 5.0

var target_node: Node3D
var current_velocity: Vector3 = Vector3.ZERO
var last_target_position: Vector3 = Vector3.ZERO

func _ready():
	print("CameraController: Starting _ready()")
	# Wait for scene to be fully ready
	call_deferred("setup_target")
	print("CameraController: setup_target deferred")

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
	
	# Get target position
	var target_position = target_node.global_position
	
	# Calculate desired camera position (fixed offset, no dynamic movement)
	var desired_position = target_position + follow_offset
	
	# Enforce distance constraints
	var distance_to_target = desired_position.distance_to(target_position)
	if distance_to_target > max_follow_distance:
		var direction = (desired_position - target_position).normalized()
		desired_position = target_position + direction * max_follow_distance
	elif distance_to_target < min_follow_distance:
		var direction = (desired_position - target_position).normalized()
		desired_position = target_position + direction * min_follow_distance
	
	# Very smooth camera movement
	global_position = global_position.lerp(desired_position, position_smoothness * delta)
	
	# Simple look-at with smooth rotation
	var look_target = target_position + Vector3(0, 1, 0)  # Look slightly above player
	var direction_to_target = (look_target - global_position).normalized()
	var target_basis = Basis.looking_at(direction_to_target, Vector3.UP)
	
	# Very smooth rotation
	basis = basis.slerp(target_basis, rotation_smoothness * delta)

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

func create_ball():
	var ball_scene = preload("res://scenes/ball/Ball3D_Simple.tscn")
	var ball_instance = ball_scene.instantiate()
	ball_instance.transform.origin = Vector3(GameConstants.FIELD_WIDTH / 2, GameConstants.BALL_RADIUS + 0.1, GameConstants.FIELD_DEPTH / 2)
	$BallContainer.add_child(ball_instance)
