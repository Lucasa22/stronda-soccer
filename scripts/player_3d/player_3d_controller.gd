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

@onready var player_mesh = $PlayerMesh
@onready var kick_area_3d = $KickArea3D
@onready var camera_3d = get_viewport().get_camera_3d() # Assuming camera is available
@onready var kick_sound: AudioStreamPlayer3D = $KickSound if has_node("KickSound") else null

var current_look_direction = Vector3.FORWARD # Used for mesh rotation
var kick_charge_start_time: float = 0.0
var is_charging_kick: bool = false

func _physics_process(delta):
	var effective_gravity = gravity * custom_gravity_scale
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= effective_gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): # "ui_accept" is usually Spacebar
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# Movement relative to camera view
	var camera_basis = camera_3d.global_transform.basis
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

	# Smoothly rotate mesh to face movement/look direction
	if current_look_direction.length_squared() > 0.01: # Only rotate if there's a significant direction
		var current_basis = player_mesh.global_transform.basis
		var target_basis = Basis.looking_at(current_look_direction, Vector3.UP)
		# Slerp for smooth rotation of the basis
		player_mesh.global_transform.basis = current_basis.slerp(target_basis, turn_speed * delta)


	# Handle Kick Charging
	if Input.is_action_pressed("kick"):
		if not is_charging_kick:
			is_charging_kick = true
			kick_charge_start_time = Time.get_ticks_msec() / 1000.0
			# print("Started charging kick")

	if Input.is_action_just_released("kick"):
		if is_charging_kick:
			var charge_duration = (Time.get_ticks_msec() / 1000.0) - kick_charge_start_time
			_handle_kick(charge_duration)
			is_charging_kick = false
			# print("Released kick after charging for: ", charge_duration)


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
			var player_facing_dir = -player_mesh.global_transform.basis.z # Player's forward vector

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
	if player_mesh and player_mesh.get_surface_material_count() > 0:
		var mat = player_mesh.get_surface_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = color
		else: # If it's not a StandardMaterial3D, create one
			var new_mat = StandardMaterial3D.new()
			new_mat.albedo_color = color
			player_mesh.set_surface_material(0, new_mat)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Default color if not set otherwise
	set_player_color(Color.BLUE_VIOLET)
	# Add to player group for potential interactions
	add_to_group("players")


# Input mapping (ensure these are set up in Project > Project Settings > Input Map)
# "move_forward" (W, Up Arrow)
# "move_backward" (S, Down Arrow)
# "move_left" (A, Left Arrow)
# "move_right" (D, Right Arrow)
# "kick" (e.g., E, Mouse Click)
# "ui_accept" (Space for jump)
