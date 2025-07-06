extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5

@export_range(5.0, 25.0) var min_kick_force: float = 7.0 # Slightly reduced min force
@export_range(10.0, 40.0) var max_kick_force: float = 18.0 # Slightly increased max force
@export_range(0.2, 1.5) var kick_hold_time_for_max_force: float = 0.6 # Slightly shorter time for max charge

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var custom_gravity_scale: float = 1.2 # Allow tweaking gravity per player if needed

@export var acceleration: float = 60.0 # Units per second^2
@export var deceleration: float = 80.0 # Units per second^2 (higher for quicker stops)
@export var turn_speed: float = 15.0 # Radians per second for mesh rotation

# Dribbling parameters
@export_group("Dribbling")
@export var dribble_max_speed: float = 4.0 # Max player speed to maintain good dribble control
@export var dribble_force_strength: float = 15.0 # How strongly the ball is nudged
@export var dribble_forward_offset: float = 0.6 # How far in front the ideal dribble point is
@export var knock_on_force_multiplier: float = 2.5 # Multiplier for dribble_force_strength on knock-on
@export var knock_on_cooldown: float = 0.5 # Seconds before another knock-on can be performed
@export var dribble_side_offset_factor: float = 0.3 # How much input influences side position
@export var dribble_upward_nudge: float = 0.05 # Small upward force to keep ball from sticking to ground
@export var dribble_ball_max_distance: float = 1.0 # Max distance ball can be to attempt dribble control
@export var dribble_area_check_radius_factor: float = 0.8 # Factor of DribbleShape3D radius for stricter check

@export_group("AI Control")
@export var is_ai_controlled: bool = false
@export var ai_goal_to_defend_pos: Vector3 = Vector3(0, 0, -30) # Example, should be set per instance
@export var ai_defend_distance_offset: float = 5.0 # How far from goal line AI tries to stay
@export var ai_approach_ball_radius: float = 8.0 # When ball is this close, AI approaches
@export var ai_kick_ball_radius: float = 1.5 # When ball is this close, AI attempts a kick
@export var ai_update_interval: float = 0.2 # How often AI updates its logic (seconds)

var ai_time_since_last_update: float = 0.0
var current_ai_state: String = "IDLE" # States: IDLE, DEFENDING_GOAL, APPROACHING_BALL

# Reference to the ball - needs to be found or passed in for AI
var ball_node: RigidBody3D = null

@export_group("Visual Variations")
@export var player_height_scale: float = 1.0:
	set(value):
		player_height_scale = value
		if is_inside_tree(): _apply_visual_variations()
@export var player_width_scale: float = 1.0:
	set(value):
		player_width_scale = value
		if is_inside_tree(): _apply_visual_variations()


@onready var player_model: Node3D = $PlayerModel
@onready var player_model_instance: Node3D = $PlayerModel/PlayerModel3D_Instance # Reference to the actual model scene instance
@onready var kick_area_3d = $KickArea3D
@onready var dribble_area_3d: Area3D = $DribbleArea3D if has_node("DribbleArea3D") else null
@onready var camera_3d = get_viewport().get_camera_3d() # Assuming camera is available for human player
@onready var kick_sound: AudioStreamPlayer3D = $KickSound if has_node("KickSound") else null
# @onready var player_number_label: Label3D = $PlayerModel/Skeleton3D/PlayerNumberLabel # Will be set up in PlayerModel3D.tscn

var current_look_direction = Vector3.FORWARD # Used for model rotation
var kick_charge_start_time: float = 0.0
var is_charging_kick: bool = false
var ball_being_dribbled: RigidBody3D = null
var last_knock_on_time: float = -knock_on_cooldown # Initialize to allow immediate first knock-on


func _unhandled_input(event):
	if is_ai_controlled: return # AI does not use direct unhandled_input for actions like this

	if event.is_action_pressed("sprint_knock_on") and ball_being_dribbled and not is_charging_kick:
		if (Time.get_ticks_msec() / 1000.0) - last_knock_on_time > knock_on_cooldown:
			_perform_knock_on()
			last_knock_on_time = Time.get_ticks_msec() / 1000.0

func _perform_knock_on():
	if not ball_being_dribbled:
		return

	var knock_on_dir = current_look_direction.normalized() # Direction player is moving/facing
	knock_on_dir.y = 0.1 # Slight upward component to lift the ball a bit
	knock_on_dir = knock_on_dir.normalized()

	var force = knock_on_dir * dribble_force_strength * knock_on_force_multiplier
	ball_being_dribbled.apply_central_impulse(force)
	# print("Performed knock-on with force: ", force)
	# Optionally, play a specific sound for knock-on
	# if kick_sound and kick_sound.stream: kick_sound.play() # Or a different sound


func _physics_process(delta):
	if is_ai_controlled:
		_ai_physics_process(delta)
	else:
		_human_physics_process(delta)

func _human_physics_process(delta):
	var effective_gravity = gravity * custom_gravity_scale
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= effective_gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): # "ui_accept" is usually Spacebar
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# Movement relative to camera view
	var current_camera = get_viewport().get_camera_3d() # Ensure we use the active camera
	if not is_instance_valid(current_camera):
		push_warning("Player controller needs a valid camera in the viewport for human control.")
		return

	var camera_basis = current_camera.global_transform.basis
	var forward_cam = -camera_basis.z.normalized().slide(Vector3.UP) # Project on XZ plane
	var right_cam = camera_basis.x.normalized().slide(Vector3.UP)   # Project on XZ plane

	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction_input = (right_cam * input_vec.x + forward_cam * input_vec.y).normalized()

	var target_velocity = Vector3.ZERO
	if move_direction_input:
		target_velocity.x = move_direction_input.x * SPEED
		target_velocity.z = move_direction_input.z * SPEED
		current_look_direction = move_direction_input # Update look direction for mesh when moving

	# Apply acceleration / deceleration
	if move_direction_input.length_squared() > 0: # Accelerating
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else: # Decelerating
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

	move_and_slide()

	# Smoothly rotate model to face movement/look direction
	if current_look_direction.length_squared() > 0.01: # Only rotate if there's a significant direction
		if is_instance_valid(player_model):
			var current_basis = player_model.global_transform.basis
			var target_basis = Basis.looking_at(current_look_direction, Vector3.UP)
			# Slerp for smooth rotation of the basis
			player_model.global_transform.basis = current_basis.slerp(target_basis, turn_speed * delta)

	# Attempt to dribble
	_handle_dribbling(delta, move_direction_input)

	# Handle Kick Charging
	if Input.is_action_pressed("kick") and not ball_being_dribbled : # Don't charge kick if actively dribbling close
		if not is_charging_kick:
			is_charging_kick = true
			kick_charge_start_time = Time.get_ticks_msec() / 1000.0

	if Input.is_action_just_released("kick"):
		if is_charging_kick:
			var charge_duration = (Time.get_ticks_msec() / 1000.0) - kick_charge_start_time
			_handle_kick(charge_duration)
			is_charging_kick = false
		elif ball_being_dribbled: # If kick is tapped while dribbling, maybe a small pass/shot
			_handle_kick(0.05) # Treat as a very short charge kick


func _find_closest_ball_in_area(area: Area3D) -> RigidBody3D:
	if not is_instance_valid(area):
		return null

	var bodies = area.get_overlapping_bodies()
	var closest_ball: RigidBody3D = null
	var min_dist_sq = INF
	for body in bodies:
		if body.is_in_group("ball") and body is RigidBody3D:
			var dist_sq = global_position.distance_squared_to(body.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest_ball = body
	return closest_ball

func _handle_dribbling(delta: float, p_move_direction_input: Vector2):
	var previously_dribbled_ball = ball_being_dribbled # Store reference to ball from previous frame
	ball_being_dribbled = null # Reset each frame, will be re-assigned if conditions met

	var current_speed_sq = velocity.length_squared()

	if not dribble_area_3d:
		if previously_dribbled_ball and previously_dribbled_ball.has_method("set_is_being_dribbled"):
			previously_dribbled_ball.set_is_being_dribbled(false) # Ensure ball physics reset
		return

	if current_speed_sq > (dribble_max_speed * dribble_max_speed) or is_charging_kick:
		if previously_dribbled_ball and previously_dribbled_ball.has_method("set_is_being_dribbled"):
			previously_dribbled_ball.set_is_being_dribbled(false)
		return

	var ball_to_control_this_frame = _find_closest_ball_in_area(dribble_area_3d)

	if not ball_to_control_this_frame:
		var ball_in_kick_zone = _find_closest_ball_in_area(kick_area_3d)
		if ball_in_kick_zone:
			var dist_to_kick_zone_ball = global_position.distance_to(ball_in_kick_zone.global_position)
			var dribble_shape = dribble_area_3d.get_node_or_null("DribbleShape3D") as CollisionShape3D
			if dribble_shape and dribble_shape.shape is SphereShape3D:
				var effective_dribble_radius = dribble_shape.shape.radius * dribble_area_check_radius_factor
				if dist_to_kick_zone_ball < effective_dribble_radius:
					ball_to_control_this_frame = ball_in_kick_zone
			elif dist_to_kick_zone_ball < dribble_ball_max_distance * 0.5:
				ball_to_control_this_frame = ball_in_kick_zone

	if not ball_to_control_this_frame:
		if previously_dribbled_ball and previously_dribbled_ball.has_method("set_is_being_dribbled"):
			previously_dribbled_ball.set_is_being_dribbled(false)
		return

	# If we switched balls or started dribbling a new one
	if previously_dribbled_ball and previously_dribbled_ball != ball_to_control_this_frame and previously_dribbled_ball.has_method("set_is_being_dribbled"):
		previously_dribbled_ball.set_is_being_dribbled(false)

	var ball_pos = ball_to_control_this_frame.global_position
	var player_pos = global_position
	var dist_to_ball = player_pos.distance_to(ball_pos)

	if dist_to_ball < dribble_ball_max_distance :
		if ball_to_control_this_frame.has_method("set_is_being_dribbled"):
			ball_to_control_this_frame.set_is_being_dribbled(true)
		ball_being_dribbled = ball_to_control_this_frame

		# Calculate ideal ball position relative to player's facing direction (current_look_direction)
		var player_forward = current_look_direction.normalized()
		var player_right = player_forward.cross(Vector3.UP).normalized()

		# Lateral input influences the side position of the ball slightly
		var lateral_influence = player_right * p_move_direction_input.x * dribble_side_offset_factor
		var ideal_ball_local_pos = player_forward * dribble_forward_offset + lateral_influence
		ideal_ball_local_pos.y = ball.global_transform.origin.y - player_pos.y # Keep ball at its current height relative to player for now

		var target_ball_world_pos = player_pos + ideal_ball_local_pos

		# Force to move ball towards this ideal position
		var force_dir_to_ideal = (target_ball_world_pos - ball_pos).normalized()
		var distance_factor = clamp(1.0 - (dist_to_ball / dribble_ball_max_distance), 0.1, 1.0) # Stronger force if further

		var dribble_nudge_force = force_dir_to_ideal * dribble_force_strength * distance_factor

		# Add a small upward nudge to prevent sticking and simulate lifting touches
		dribble_nudge_force.y += dribble_upward_nudge * dribble_force_strength

		# Apply force more aligned with player's current velocity direction if moving significantly
		if velocity.length_squared() > 0.1:
			var vel_dir = velocity.normalized()
			# Blend the ideal position force with velocity direction force
			dribble_nudge_force = dribble_nudge_force.lerp(vel_dir * dribble_nudge_force.length(), 0.3)


		ball.apply_central_force(dribble_nudge_force)

		# Dampen ball's velocity slightly if it's moving too fast away from player during dribble
		var ball_vel_relative_to_player = ball.linear_velocity - velocity
		if ball_vel_relative_to_player.length() > SPEED * 0.8: # If ball is escaping too fast
			ball.linear_velocity = ball.linear_velocity.lerp(velocity, 0.1)


func _handle_kick(charge_duration: float):
	var charge_ratio = clamp(charge_duration / kick_hold_time_for_max_force, 0.0, 1.0)
	var current_kick_force = lerp(min_kick_force, max_kick_force, charge_ratio)
	# print(f"Kick force: {current_kick_force} (Charge: {charge_ratio*100}%)")

	var bodies = kick_area_3d.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("ball"): # Make sure Ball3D is added to "ball" group

			# Kick direction towards where the camera is looking, but projected on XZ plane initially
			var kick_dir_forward = -camera_3d.global_transform.basis.z.normalized()
			kick_dir_forward.y = 0 # Keep it mostly horizontal for now
			kick_dir_forward = kick_dir_forward.normalized()

			# Add slight upward angle based on charge or a fixed value
			var upward_angle = lerp(0.1, 0.4, charge_ratio) # More charge = slightly higher kick
			if Input.is_action_pressed("aim_high"): # Add a dedicated "aim_high" input for lob shots
				upward_angle = lerp(0.5, 0.8, charge_ratio) # Higher lob

			kick_dir_forward.y = upward_angle
			var final_kick_dir = kick_dir_forward.normalized()

			# Ensure the ball is somewhat in front of the player relative to player's look_direction (current_look_direction)
			var ball_to_player_dir = (global_position - body.global_position).normalized()
			var player_facing_dir = Vector3.FORWARD # Default, will be updated if model is valid
			if is_instance_valid(player_model):
				player_facing_dir = -player_model.global_transform.basis.z # Player's forward vector

			# More lenient check: ensure the ball is generally in the forward arc of the player
			# and also that the player is generally facing the ball.
			var dot_player_to_ball = player_facing_dir.dot(-ball_to_player_dir) # Player facing towards ball?
			var dot_kick_area_to_ball = kick_area_3d.global_transform.basis.z.dot(-ball_to_player_dir) # KickArea facing ball?

			# Thresholds (can be tweaked)
			# Player needs to be generally facing the ball.
			# KickArea (which is tied to player mesh orientation) also needs to be generally facing the ball.
			if dot_player_to_ball > 0.3 and dot_kick_area_to_ball > 0.0:
				body.apply_central_impulse(final_kick_dir * current_kick_force)
				print(f"Kicked ball with force {current_kick_force} in direction {final_kick_dir}")
				if kick_sound and kick_sound.stream: # Check if sound node and stream are valid
					kick_sound.play()
			else:
				print(f"Ball not in ideal kicking position. Player_dot: {dot_player_to_ball}, KickArea_dot: {dot_kick_area_to_ball}")
			return # Kick one ball at a time

func set_player_name(new_name):
	var label = $PlayerNameLabel3D
	if label:
		label.text = new_name

func set_player_color(color: Color):
	if not is_instance_valid(player_model_instance):
		push_warning("PlayerModel3D instance is not valid, cannot set player color.")
		return

	# The Mesh_Body is inside PlayerModel3D.tscn, unique name was not set for it, so using path
	var body_mesh_node = player_model_instance.get_node_or_null("Skeleton3D/BA_Hips/Mesh_Body")

	if body_mesh_node and body_mesh_node is MeshInstance3D:
		var mesh_instance = body_mesh_node as MeshInstance3D
		# Ensure the material is a ShaderMaterial, as set up in PlayerModel3D.tscn
		var mat = mesh_instance.get_surface_override_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("team_color", color)
		else:
			# Fallback if material setup was incorrect or changed, though ideally this shouldn't be needed.
			push_warning("Mesh_Body in PlayerModel3D_Instance does not have the expected ShaderMaterial. Attempting to create and apply.")
			var new_shader_mat = ShaderMaterial.new()
			new_shader_mat.shader = load("res://shaders/team_color_shader.gdshader")
			if new_shader_mat.shader: # Check if shader loaded successfully
				new_shader_mat.set_shader_parameter("team_color", color)
				mesh_instance.set_surface_override_material(0, new_shader_mat)
			else:
				push_error("Failed to load team_color_shader.gdshader for fallback.")
	else:
		push_warning("Could not find Mesh_Body at 'Skeleton3D/BA_Hips/Mesh_Body' in PlayerModel3D_Instance to apply color.")


func set_player_number(number: String):
	if not is_instance_valid(player_model_instance):
		push_warning("PlayerModel3D instance is not valid, cannot set player number.")
		return

	var number_label_node = player_model_instance.get_node_or_null("%PlayerNumberLabel")
	if number_label_node and number_label_node is Label3D:
		var label = number_label_node as Label3D
		label.text = number
	else:
		push_warning("PlayerNumberLabel not found using unique name '%PlayerNumberLabel' in PlayerModel3D_Instance.")


func set_hairstyle(style_id: int): # Added new function
	if not is_instance_valid(player_model_instance):
		push_warning("PlayerModel3D instance is not valid, cannot set hairstyle.")
		return

	var hairstyle_node = player_model_instance.get_node_or_null("%HairstyleDefault")
	if hairstyle_node and hairstyle_node is MeshInstance3D:
		if style_id == 0: # Default hairstyle
			hairstyle_node.visible = true
		# Example for future:
		# var hairstyle_alt_node = player_model_instance.get_node_or_null("%HairstyleAlt")
		# if style_id == 1 and hairstyle_alt_node:
		#    hairstyle_node.visible = false
		#    hairstyle_alt_node.visible = true
		else: # Hide default if other styles are chosen (and not yet implemented) or if style_id is invalid
			hairstyle_node.visible = false
			if style_id != 0 : push_warning("Hairstyle ID " + str(style_id) + " selected, but only style 0 (Default) is currently implemented. Hiding default.")
	else:
		push_warning("HairstyleDefault node not found or not a MeshInstance3D in PlayerModel3D_Instance.")


func _apply_visual_variations():
	if not is_instance_valid(player_model): # player_model is the Node3D container $PlayerModel
		push_warning("PlayerModel (the container Node3D) is not valid, cannot apply visual variations.")
		return
	# Scale the container node. The PlayerModel3D_Instance inside it will scale accordingly.
	player_model.scale = Vector3(player_width_scale, player_height_scale, player_width_scale)
	# print(f"Applied visual variations: H={player_height_scale}, W={player_width_scale} to $PlayerModel container")

# Called when the node enters the scene tree for the first time.
func _ready():
	# It's good practice to wait for children to be ready if relying on them,
	# but @onready should handle player_model_instance.
	# If issues arise, could use `await owner.ready` or `call_deferred` for setups.

	# Default color if not set otherwise
	set_player_color(Color.BLUE_VIOLET) # Example team color
	_apply_visual_variations() # Apply initial scale
	set_player_number("10") # Example player number
	set_hairstyle(0) # Apply default hairstyle (shows the default mesh)

	# Add to player group for potential interactions
	add_to_group("players")

	if is_ai_controlled:
		# AI needs a reference to the ball. This is a simple way, assumes one ball.
		# In a real game, a game manager or event system might provide this.
		var ball_nodes = get_tree().get_nodes_in_group("ball")
		if ball_nodes.size() > 0:
			ball_node = ball_nodes[0] as RigidBody3D # Get the first ball found
		else:
			print_warning(name + " (AI): No ball found in group 'ball'. AI will be idle.")
			is_ai_controlled = false # Disable AI if no ball

		# Ensure camera is not the main game camera if AI controlled, to avoid conflicts
		# This assumes the AI player might have its own (disabled) camera or none.
		# If AI is using the main camera for decision making, this needs adjustment.
		var main_cam = get_viewport().get_camera_3d()
		if main_cam == camera_3d and is_ai_controlled: # Check if this instance's camera_3d is the viewport's main camera
			# This AI shouldn't rely on the main player's camera for its logic if it's not that player.
			# For now, we'll assume AI logic is independent of a specific camera view for its decisions.
			pass


# --- AI Specific Logic ---
func _ai_get_move_input(target_pos: Vector3) -> Vector2:
	var direction_to_target = (target_pos - global_position).normalized()
	# Convert world direction to local input vector (approximated)
	# This is a simplified conversion. A more robust way might involve projecting to player's local XZ plane.
	var model_forward_dir = Vector3.FORWARD
	var model_right_dir = Vector3.RIGHT
	if is_instance_valid(player_model):
		model_forward_dir = -player_model.global_transform.basis.z # Player's current forward
		model_right_dir = player_model.global_transform.basis.x   # Player's current right

	var dot_fwd = direction_to_target.dot(model_forward_dir)
	var dot_right = direction_to_target.dot(right_dir)

	var input_x = 0.0
	var input_y = 0.0

	if abs(dot_fwd) > 0.2: # Threshold to move
		input_y = sign(dot_fwd)
	if abs(dot_right) > 0.2: # Threshold to move
		input_x = sign(dot_right)

	return Vector2(input_x, input_y).normalized() # Return as Vector2 for existing movement logic


func _ai_physics_process(delta):
	if not ball_node or not is_instance_valid(ball_node):
		# print_debug(name + " (AI): Ball node invalid, idling.")
		velocity = velocity.move_toward(Vector3.ZERO, deceleration * delta) # Slow down
		move_and_slide()
		return

	ai_time_since_last_update += delta
	if ai_time_since_last_update < ai_update_interval:
		# Apply existing velocity if any (from previous frame's decision)
		if velocity.length_squared() > 0.01:
			move_and_slide()
		return # Update AI logic less frequently for performance

	ai_time_since_last_update = 0.0 # Reset timer

	var ball_pos = ball_node.global_position
	var my_pos = global_position
	var dist_to_ball_sq = my_pos.distance_squared_to(ball_pos)

	# --- AI State Logic ---
	if dist_to_ball_sq < ai_approach_ball_radius * ai_approach_ball_radius:
		current_ai_state = "APPROACHING_BALL"
	else:
		current_ai_state = "DEFENDING_GOAL"
	# --- End AI State Logic ---

	var move_input_ai = Vector2.ZERO
	var should_try_kick_ai = false

	match current_ai_state:
		"DEFENDING_GOAL":
			var point_on_goal_line = ai_goal_to_defend_pos
			var vector_from_goal_to_ball = (ball_pos - point_on_goal_line).normalized()
			var defend_target_pos = point_on_goal_line + vector_from_goal_to_ball * ai_defend_distance_offset
			defend_target_pos.y = global_position.y # Keep AI at its current height
			move_input_ai = _ai_get_move_input(defend_target_pos)
			# print_debug(name + " (AI): Defending. Target: " + str(defend_target_pos))

		"APPROACHING_BALL":
			var approach_target_pos = ball_pos
			approach_target_pos.y = global_position.y # Keep AI at its current height
			move_input_ai = _ai_get_move_input(approach_target_pos)
			# print_debug(name + " (AI): Approaching ball. Target: " + str(approach_target_pos))
			if dist_to_ball_sq < ai_kick_ball_radius * ai_kick_ball_radius:
				should_try_kick_ai = true

	# --- Apply AI Decisions to Movement ---
	# (This part reuses the human player's movement logic, but with AI-generated input)
	var target_vel_ai = Vector3.ZERO
	if move_input_ai.length_squared() > 0.01 :
		# AI movement is world-based, not camera-relative
		var world_move_dir = Vector3(move_input_ai.x, 0, move_input_ai.y).normalized()
		# To make AI use its own orientation for "forward/right" in _ai_get_move_input,
		# we need to ensure current_look_direction is updated based on AI's intended movement.
		# For now, let's make it simpler: AI moves in world directions.
		# The _ai_get_move_input gives a local-space-like input, let's convert that.
		# This needs refinement if AI is to behave like player with camera-relative input.
		# Simplification: AI directly controls world velocity direction.

		# If _ai_get_move_input returns (0,1) it means "move towards target".
		# We need to convert that target direction into velocity.
		var dir_to_move = Vector3.ZERO
		if current_ai_state == "DEFENDING_GOAL":
			var point_on_goal_line_def = ai_goal_to_defend_pos
			var vector_from_goal_to_ball_def = (ball_pos - point_on_goal_line_def).normalized()
			var defend_target_pos_def = point_on_goal_line_def + vector_from_goal_to_ball_def * ai_defend_distance_offset
			dir_to_move = (defend_target_pos_def - global_position).normalized()
		elif current_ai_state == "APPROACHING_BALL":
			dir_to_move = (ball_pos - global_position).normalized()

		if dir_to_move.length_squared() > 0.01:
			target_vel_ai.x = dir_to_move.x * SPEED
			target_vel_ai.z = dir_to_move.z * SPEED
			current_look_direction = dir_to_move # AI looks where it's going

	if target_vel_ai.length_squared() > 0:
		velocity.x = move_toward(velocity.x, target_vel_ai.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel_ai.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

	move_and_slide()

	if current_look_direction.length_squared() > 0.01:
		if is_instance_valid(player_model):
			var current_basis_ai = player_model.global_transform.basis
			var target_basis_ai = Basis.looking_at(current_look_direction, Vector3.UP)
			player_model.global_transform.basis = current_basis_ai.slerp(target_basis_ai, turn_speed * delta)

	# --- AI Kicking ---
	if should_try_kick_ai and not is_charging_kick: # AI doesn't charge kicks for now
		# Simple kick towards opponent's goal (assuming it's opposite of ai_goal_to_defend_pos)
		var opponent_goal_pos = -ai_goal_to_defend_pos
		opponent_goal_pos.y = ball_pos.y # Kick at ball height

		var bodies_in_kick_area = kick_area_3d.get_overlapping_bodies()
		for body_in_kick in bodies_in_kick_area:
			if body_in_kick == ball_node: # If the ball is in our kick area
				var kick_direction_ai = (opponent_goal_pos - ball_pos).normalized()
				# Apply a slight upward angle to the kick for AI
				kick_direction_ai.y = 0.15
				kick_direction_ai = kick_direction_ai.normalized()

				ball_node.apply_central_impulse(kick_direction_ai * min_kick_force) # AI uses min_kick_force for now
				# print_debug(name + " (AI): Kicked ball towards " + str(opponent_goal_pos))
				if kick_sound and kick_sound.stream: kick_sound.play()
				break # Kicked once
	# --- End AI Kicking ---


# Input mapping (ensure these are set up in Project > Project Settings > Input Map)
# "move_forward" (W, Up Arrow)
# "move_backward" (S, Down Arrow)
# "move_left" (A, Left Arrow)
# "move_right" (D, Right Arrow)
# "kick" (e.g., E, Mouse Click)
# "ui_accept" (Space for jump)
