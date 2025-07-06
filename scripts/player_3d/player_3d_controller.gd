extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5

@export_range(5.0, 20.0) var min_kick_force: float = 8.0
@export_range(10.0, 30.0) var max_kick_force: float = 15.0
@export_range(0.0, 1.0) var kick_hold_time_for_max_force: float = 0.7 # seconds

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var player_mesh = $PlayerMesh
@onready var kick_area_3d = $KickArea3D
@onready var camera_3d = get_viewport().get_camera_3d() # Assuming camera is available
@onready var kick_sound: AudioStreamPlayer3D = $KickSound if has_node("KickSound") else null

var look_direction = Vector3.FORWARD
var kick_charge_start_time: float = 0.0
var is_charging_kick: bool = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): # "ui_accept" is usually Spacebar
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# Movement relative to camera view
	var camera_basis = camera_3d.global_transform.basis
	var forward = -camera_basis.z.normalized().slide(Vector3.UP) # Project on XZ plane
	var right = camera_basis.x.normalized().slide(Vector3.UP)   # Project on XZ plane

	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction = (right * input_vec.x + forward * input_vec.y).normalized()

	if move_direction:
		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
		look_direction = move_direction # Update look direction when moving
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 5.0) # Faster deceleration
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * 5.0) # Faster deceleration

	move_and_slide()

	# Rotate mesh to face movement direction (simple rotation, can be smoothed later)
	if move_direction:
		var target_look_at = global_position + move_direction
		player_mesh.look_at(target_look_at, Vector3.UP)

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

			# Ensure the ball is somewhat in front of the player relative to player's look_direction
			var ball_relative_pos = body.global_position - global_position
			if player_mesh.global_transform.basis.z.dot(ball_relative_pos.normalized()) < -0.2: # Check if ball is roughly in front
				body.apply_central_impulse(final_kick_dir * current_kick_force)
				print(f"Kicked ball with force {current_kick_force} in direction {final_kick_dir}")
				if kick_sound and kick_sound.stream: # Check if sound node and stream are valid
					kick_sound.play()
			else:
				print("Ball not in front, kick misaligned.")
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
