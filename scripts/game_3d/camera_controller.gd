extends Camera3D

@export var target_path: NodePath # NodePath to the player or target to follow
@export var offset: Vector3 = Vector3(0, 15, 10) # Default offset from target
@export var look_at_offset: Vector3 = Vector3(0, 1, 0) # Point slightly above the target's origin
@export var smoothness: float = 5.0 # How quickly the camera follows (higher is faster)

var target_node: Node3D

func _ready():
	if target_path:
		target_node = get_node_or_null(target_path)
	if not target_node:
		print_warning("Camera target not found or not set: " + str(target_path))
		# Fallback: if no target, position camera at its current transform or a default spot
		# For now, it will just stay static if no target.
		set_process(false) # Disable processing if no target
		return

	# Set initial position immediately without smoothing
	if is_instance_valid(target_node):
		global_transform.origin = target_node.global_transform.origin + offset
		look_at(target_node.global_transform.origin + look_at_offset, Vector3.UP)

func _physics_process(delta):
	if not is_instance_valid(target_node):
		# Target might have been freed (e.g., player despawned)
		# Could add logic here to find a new target or switch to a static mode
		if target_path: # Try to re-acquire if path is set
			target_node = get_node_or_null(target_path)
		if not is_instance_valid(target_node):
			return # Still no valid target, do nothing

	var desired_position = target_node.global_transform.origin + offset
	global_transform.origin = global_transform.origin.lerp(desired_position, delta * smoothness)

	# Always look at the target
	# Consider lerping look_at for smoother rotation if needed, but direct look_at is often fine
	look_at(target_node.global_transform.origin + look_at_offset, Vector3.UP)

func set_target(new_target_node: Node3D):
	if is_instance_valid(new_target_node):
		target_node = new_target_node
		target_path = get_path_to(new_target_node) # Update NodePath if setting programmatically
		set_process(true) # Ensure processing is enabled
		# Optionally, snap to new target immediately
		# global_transform.origin = target_node.global_transform.origin + offset
		# look_at(target_node.global_transform.origin + look_at_offset, Vector3.UP)
	else:
		print_warning("Attempted to set invalid camera target.")

func set_offset(new_offset: Vector3):
	offset = new_offset

func set_look_at_offset(new_look_at_offset: Vector3):
	look_at_offset = new_look_at_offset

# Example: If you want to dynamically change camera based on game state
# func switch_to_tactical_view():
#	offset = Vector3(0, 30, 20) # Higher and further back
#	look_at_offset = Vector3(0,0,0) # Look at the ground center of player

# func switch_to_action_view():
#	offset = Vector3(0, 5, 7) # Closer
#	look_at_offset = Vector3(0,1,0) # Look at player's torso
