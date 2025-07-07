extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var is_ai_controlled: bool = false
var player_team_color: Color = Color.BLUE
var ball_node: RigidBody3D

# Realistic kick system variables
@export var min_kick_force: float = 3.0   # Light touch
@export var max_kick_force: float = 25.0  # Power shot
@export var kick_charge_time: float = 1.2  # Time to full charge
@export var kick_accuracy: float = 0.85   # 85% accuracy when perfectly aimed
var kick_power: float = 0.0
var is_charging_kick: bool = false
var kick_cooldown: float = 0.0
var last_kick_direction: Vector3 = Vector3.ZERO
var kick_contact_point: Vector3 = Vector3.ZERO

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $PlayerNameLabel3D
@onready var kick_area: Area3D = $KickArea3D

func _ready():
	# Set collision layers
	collision_layer = 1  # Player layer
	collision_mask = 1 | 4 | 8  # Collide with other players (1), ball (4), walls/ground (8)
	
	# Add to player group
	add_to_group("players")
	
	# Set default color
	if mesh_instance and mesh_instance.material_override == null:
		var material = StandardMaterial3D.new()
		material.albedo_color = player_team_color
		mesh_instance.material_override = material
	
	print("Player initialized at position: ", global_position)
	print("Player ", name, " is AI controlled: ", is_ai_controlled)
	
	# Ensure only Player1 is human controlled by default
	if name == "Player1":
		is_ai_controlled = false
		print("Player1 set as human controlled")
	elif name == "AIPlayer1":
		is_ai_controlled = true
		print("AIPlayer1 set as AI controlled")

func _physics_process(delta: float) -> void:
	# Update cooldowns
	if kick_cooldown > 0:
		kick_cooldown -= delta
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if velocity.y < 0:
			velocity.y = 0  # Stop falling when on floor

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_ai_controlled:
		velocity.y = JUMP_VELOCITY
		print("Player jumped!")

	# Handle movement
	if not is_ai_controlled:
		_handle_player_input(delta)
	else:
		_handle_ai_logic(delta)

	# Handle kick charging and execution
	_handle_kick_system(delta)

	move_and_slide()
	
	# Debug floor detection
	if is_on_floor() and position.y < 0.5:
		pass # Removed excessive debug print

func _handle_player_input(delta: float):
	# Only process input if this is the human player (not AI)
	if is_ai_controlled:
		return
	
	# Simplified input handling 
	var input_vec = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_vec.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vec.x += 1
	if Input.is_action_pressed("move_forward"):
		input_vec.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_vec.y += 1
	
	if input_vec.length() > 0:
		velocity.x = input_vec.x * SPEED
		velocity.z = input_vec.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 3)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * 3)

func _handle_ai_logic(delta: float):
	# Simple AI: move towards ball
	if ball_node:
		var direction_to_ball = (ball_node.global_position - global_position).normalized()
		velocity.x = direction_to_ball.x * SPEED * 0.7
		velocity.z = direction_to_ball.z * SPEED * 0.7
		
		# Debug AI movement
		if randf() < 0.01:  # Print occasionally to avoid spam
			print("AI Player moving towards ball at: ", ball_node.global_position)

func _handle_kick_system(delta: float):
	if is_ai_controlled:
		_handle_ai_kick()
		return
	
	# Human player kick system with charging
	if Input.is_action_pressed("kick") and kick_cooldown <= 0:
		if not is_charging_kick:
			is_charging_kick = true
			kick_power = 0.0
			print("Started charging kick...")
		
		# Charge the kick
		kick_power = min(kick_power + delta / kick_charge_time, 1.0)
		
		# Visual feedback for charging (make player slightly bigger)
		if mesh_instance:
			var scale_factor = 1.0 + (kick_power * 0.2)
			mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	elif is_charging_kick:
		# Release the kick
		_execute_kick()
		is_charging_kick = false
		kick_power = 0.0
		
		# Reset visual feedback
		if mesh_instance:
			mesh_instance.scale = Vector3.ONE

func _execute_kick():
	var nearby_balls = kick_area.get_overlapping_bodies()
	
	for body in nearby_balls:
		if body is RigidBody3D and body.is_in_group("ball"):
			_kick_ball_realistic(body)
			break

func _kick_ball_realistic(ball: RigidBody3D):
	# Calculate kick contact point (where foot meets ball)
	var ball_center = ball.global_position
	var player_foot_pos = global_position + Vector3(0, 0.2, 0) # Foot height
	kick_contact_point = ball_center + (player_foot_pos - ball_center).normalized() * 0.11
	
	# Calculate kick direction based on foot position and movement
	var kick_direction = _calculate_realistic_kick_direction(ball, kick_contact_point)
	
	# Calculate force magnitude (power curve for realistic feel)
	var force_magnitude = _calculate_kick_force()
	
	# Add spin based on contact point and kick style
	var spin = _calculate_ball_spin(ball, kick_direction, kick_contact_point)
	
	# Apply physics-based kick
	if ball.has_method("apply_kick_force"):
		ball.apply_kick_force(kick_direction, force_magnitude, spin)
	else:
		# Fallback for basic ball
		ball.apply_central_impulse(kick_direction * force_magnitude)
	
	# Set cooldown based on kick power
	kick_cooldown = 0.2 + (kick_power * 0.3)
	
	# Enhanced feedback
	_provide_kick_feedback(kick_power, force_magnitude)
	
	last_kick_direction = kick_direction

func _calculate_realistic_kick_direction(ball: RigidBody3D, contact_point: Vector3) -> Vector3:
	var ball_center = ball.global_position
	var player_center = global_position
	
	# Get player movement direction
	var movement_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	
	# Calculate the direction from contact point through ball center
	var through_ball_direction = (ball_center - contact_point).normalized()
	
	# Blend movement direction with contact physics
	var base_direction: Vector3
	if movement_direction.length() > 0.1:
		# Moving kick - blend movement with contact
		base_direction = (movement_direction * 0.7 + through_ball_direction * 0.3).normalized()
	else:
		# Standing kick - use contact point physics
		base_direction = through_ball_direction
	
	# Add elevation based on contact point (lower contact = higher ball)
	var contact_height_factor = (contact_point.y - (ball_center.y - 0.11)) / 0.22
	var elevation = 0.15 + (1.0 - contact_height_factor) * 0.4 + (kick_power * 0.2)
	
	# Apply accuracy - higher power can reduce accuracy
	var accuracy_factor = kick_accuracy * (1.0 - kick_power * 0.2)
	var angle_variation = (1.0 - accuracy_factor) * PI * 0.3
	var random_angle = randf_range(-angle_variation, angle_variation)
	
	# Rotate direction by random angle for accuracy simulation
	base_direction = base_direction.rotated(Vector3.UP, random_angle)
	base_direction.y += elevation
	
	return base_direction.normalized()

func _calculate_kick_force() -> float:
	# Non-linear power curve for more realistic feel (manual ease_in_out)
	var power_curve = kick_power * kick_power * (3.0 - 2.0 * kick_power)
	var base_force = lerp(min_kick_force, max_kick_force, power_curve)
	
	# Add player velocity bonus (running kick is stronger)
	var velocity_bonus = min(velocity.length() * 0.8, 4.0)
	
	return base_force + velocity_bonus

func _calculate_ball_spin(ball: RigidBody3D, kick_direction: Vector3, contact_point: Vector3) -> Vector3:
	var ball_center = ball.global_position
	var contact_offset = contact_point - ball_center
	
	# Side spin based on horizontal contact offset
	var side_spin = Vector3.UP * contact_offset.x * kick_power * 15.0
	
	# Back/top spin based on vertical contact offset
	var vertical_spin_axis = kick_direction.cross(Vector3.UP).normalized()
	var back_spin = vertical_spin_axis * contact_offset.y * kick_power * 12.0
	
	return side_spin + back_spin

func _provide_kick_feedback(power: float, force: float):
	print("KICK! Power: %.2f Force: %.1f" % [power, force])
	
	# Enhanced visual feedback
	if mesh_instance:
		var tween = create_tween()
		var flash_intensity = 0.3 + (power * 0.7)
		var flash_color = Color.YELLOW.lerp(Color.ORANGE, power)
		
		tween.tween_property(mesh_instance, "modulate", flash_color, 0.05)
		tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.15)
	
	# Screen shake effect (could be implemented in camera)
	# Particle effect (could be added later)

func _calculate_kick_direction(ball: RigidBody3D) -> Vector3:
	# Get the direction the player is facing (based on movement input)
	var movement_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	
	# If no movement, kick towards ball direction from player
	if movement_direction.length() < 0.1:
		movement_direction = (ball.global_position - global_position).normalized()
	
	# Combine movement direction with ball position for more natural kicking
	var to_ball = (ball.global_position - global_position).normalized()
	var kick_direction = (movement_direction + to_ball * 0.3).normalized()
	
	return kick_direction

func _handle_ai_kick():
	if kick_cooldown > 0:
		return
	
	var nearby_balls = kick_area.get_overlapping_bodies()
	
	for body in nearby_balls:
		if body is RigidBody3D and body.is_in_group("ball"):
			# AI uses medium power kick (50-75% charge)
			kick_power = randf_range(0.5, 0.75)
			
			# Calculate direction to goal
			var goal_direction: Vector3
			if global_position.z < 0:
				goal_direction = Vector3(0, 0, 30)  # Kick towards player goal
			else:
				goal_direction = Vector3(0, 0, -30)  # Kick towards AI goal
			
			# Add some randomness to AI kicks
			var random_offset = Vector3(
				randf_range(-3, 3),
				0,
				randf_range(-2, 2)
			)
			goal_direction += random_offset
			
			# Use realistic kick system
			_kick_ball_realistic(body)
			
			kick_cooldown = randf_range(0.4, 0.8)  # AI has variable cooldown
			print("AI kicked the ball with power: ", kick_power)
			break

func set_ai_controlled(value: bool):
	is_ai_controlled = value
	if is_ai_controlled:
		var ball_nodes = get_tree().get_nodes_in_group("ball")
		if ball_nodes.size() > 0:
			ball_node = ball_nodes[0] as RigidBody3D

func set_player_color(color: Color):
	player_team_color = color
	if mesh_instance:
		if mesh_instance.material_override == null:
			mesh_instance.material_override = StandardMaterial3D.new()
		mesh_instance.material_override.albedo_color = color
