extends Camera3D

@export var target_path: NodePath # NodePath to the player or target to follow
@export var offset: Vector3 = Vector3(0, 12, 9) # Adjusted default offset
@export var look_at_offset: Vector3 = Vector3(0, 1.2, 0) # Point slightly above the target's origin
@export var smoothness: float = 7.0 # How quickly the camera follows
@export var collision_layer_mask: int = 1 # Layer mask for camera collision (e.g., world, static objects)
@export var collision_push_margin: float = 0.3 # How much to push camera if obstructed

var target_node: Node3D
var ideal_offset: Vector3 # Stores the original configured offset

func _ready():
	ideal_offset = offset # Store the initial offset for collision handling
	if target_path:
		target_node = get_node_or_null(target_path)
	if not target_node:
		push_warning("Camera target not found or not set: " + str(target_path))
		set_physics_process(false) # Disable processing if no target
		return

	# Set initial position immediately without smoothing
	if is_instance_valid(target_node):
		var initial_cam_pos = target_node.global_transform.origin + ideal_offset
		global_transform.origin = initial_cam_pos
		look_at(target_node.global_transform.origin + look_at_offset, Vector3.UP)

func _physics_process(delta):
	if not is_instance_valid(target_node):
		if target_path:
			target_node = get_node_or_null(target_path)
		if not is_instance_valid(target_node):
			return # Still no valid target

	var target_global_pos = target_node.global_transform.origin
	var desired_cam_pos = target_global_pos + ideal_offset # Use ideal_offset for desired position

	# Camera Collision Handling
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(target_global_pos + look_at_offset, desired_cam_pos, collision_layer_mask)
	var result = space_state.intersect_ray(query)

	var final_cam_pos: Vector3
	if result:
		# If ray hits something, move camera to the collision point, slightly pushed out
		var hit_point = result.position
		var direction_to_target = (target_global_pos + look_at_offset - hit_point).normalized()
		final_cam_pos = hit_point + direction_to_target * collision_push_margin
	else:
		# No collision, use the desired position based on ideal_offset
		final_cam_pos = desired_cam_pos

	global_transform.origin = global_transform.origin.lerp(final_cam_pos, delta * smoothness)
	look_at(target_global_pos + look_at_offset, Vector3.UP)

func set_target(new_target_node: Node3D):
	if is_instance_valid(new_target_node):
		target_node = new_target_node
		target_path = get_path_to(new_target_node) # Update NodePath if setting programmatically
		set_process(true) # Ensure processing is enabled
		# Optionally, snap to new target immediately
		# global_transform.origin = target_node.global_transform.origin + offset
		# look_at(target_node.global_transform.origin + look_at_offset, Vector3.UP)
	else:
		push_warning("Attempted to set invalid camera target.")

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
