extends CharacterBody3D

# Player movement constants - using GameConstants
const SPEED = GameConstants.PLAYER_MOVE_SPEED
const JUMP_VELOCITY = GameConstants.PLAYER_JUMP_VELOCITY
const ACCELERATION = 15.0
const DECELERATION = 8.0  # Reduced from 20.0 to 8.0

# Player rotation constants
const ROTATION_SPEED = 10.0  # How fast the player rotates to face movement direction
const USE_LOOK_AT_ROTATION = false  # Toggle between rotation methods for testing

# Player properties
@export var player_team_color: Color = Color.BLUE
@export var is_ai_controlled: bool = false

# Realistic kick system variables - using GameConstants
@export var min_kick_force: float = GameConstants.KICK_FORCE_MIN
@export var max_kick_force: float = GameConstants.KICK_FORCE_MAX
@export var kick_charge_time: float = 1.2
@export var kick_accuracy: float = 0.85
var kick_power: float = 0.0
var is_charging_kick: bool = false
var kick_cooldown: float = 0.0

# References to modular components
@onready var player_model: Node3D = $PlayerModel if has_node("PlayerModel") else null
@onready var label_3d: Label3D = $PlayerNameLabel3D if has_node("PlayerNameLabel3D") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var animation_controller: PlayerAnimationController = $PlayerAnimationController if has_node("PlayerAnimationController") else null

var kick_area: Area3D

var current_animation_state: String = ""
var animation_warnings_shown: Dictionary = {}


var balls_in_kick_range: Array[RigidBody3D] = []
var ball_detection_timer: float = 0.0  # Add small delay for stable detection

# Team color materials
var chest_mesh: MeshInstance3D
var pelvis_mesh: MeshInstance3D
var left_upper_leg_mesh: MeshInstance3D
var right_upper_leg_mesh: MeshInstance3D

func _ready():
	print("Player3D_Modular: Starting _ready()")
	
	# Verify animation player and animations
	if animation_player:
		print("Animation player found")
		if animation_player.has_animation("idle"):
			print("Idle animation found")
		else:
			print("WARNING: Idle animation not found")
		if animation_player.has_animation("run"):
			print("Run animation found")
		else:
			print("WARNING: Run animation not found")
		if animation_player.has_animation("kick"):
			print("Kick animation found")
		else:
			print("WARNING: Kick animation not found")
	else:
		print("WARNING: Animation player not found")
	
	# Set collision layers - include ground layer (16)
	collision_layer = 1
	collision_mask = 1 | 4 | 8 | 16  # Players, walls, goals, ground
	
	print("Player3D_Modular: Collision layers set")
	
	# Initialize kick area - find it in the scene
	kick_area = get_node_or_null("PlayerModel/Pelvis/RightHip/RightUpperLeg/RightLowerLeg/RightFoot/KickArea3D")
	if kick_area:
		print("Player3D_Modular: KickArea3D found")
		kick_area.body_entered.connect(_on_kick_area_body_entered)
		kick_area.body_exited.connect(_on_kick_area_body_exited)
		# Ensure the kick area can detect the ball (assuming ball is on layer 3, mask 4)
		kick_area.collision_mask = 4
		print("Player3D_Modular: KickArea3D signals connected and mask set")
	else:
		print("Player3D_Modular: WARNING - KickArea3D not found")

	# Get mesh references for team colors
	_get_mesh_references()
	print("Player3D_Modular: Mesh references obtained")

	# Set default team color
	set_player_color(Color.BLUE)
	print("Player3D_Modular: Default color set")

	# Set name label
	if label_3d:
		label_3d.text = "Player"
		print("Player3D_Modular: Name label set")
	else:
		print("Player3D_Modular: WARNING - Label3D not found")

	print("Player3D_Modular: _ready() completed successfully")


func _get_mesh_references():
	# Get references to mesh nodes for team color application
	chest_mesh = get_node_or_null("PlayerModel/Pelvis/Spine/Chest/ChestMesh")
	pelvis_mesh = get_node_or_null("PlayerModel/Pelvis/PelvisMesh")
	left_upper_leg_mesh = get_node_or_null("PlayerModel/Pelvis/LeftHip/LeftUpperLeg/LeftUpperLegMesh")
	right_upper_leg_mesh = get_node_or_null("PlayerModel/Pelvis/RightHip/RightUpperLeg/RightUpperLegMesh")

	# Debug: Report which meshes were found
	print("Player3D_Modular: Mesh references:")
	print("  - chest_mesh: ", chest_mesh != null)
	print("  - pelvis_mesh: ", pelvis_mesh != null)
	print("  - left_upper_leg_mesh: ", left_upper_leg_mesh != null)
	print("  - right_upper_leg_mesh: ", right_upper_leg_mesh != null)

func _physics_process(delta: float):
	# Early return if not ready
	if not is_inside_tree():
		return
		
	# Update cooldowns
	if kick_cooldown > 0:
		kick_cooldown -= delta
	
	
	if ball_detection_timer > 0:
		ball_detection_timer -= delta
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= GameConstants.GRAVITY * delta
		print("Player in air, Y velocity: ", velocity.y)
	else:
		if velocity.y < 0:
			velocity.y = 0
		print("Player on floor, position: ", global_position)

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_ai_controlled:
		velocity.y = JUMP_VELOCITY
		print("Player jumped!")

	# Handle movement
	if not is_ai_controlled:
		_handle_player_input(delta)
	else:
		_handle_ai_logic(delta)

	# Handle kick system
	_handle_kick_system(delta)

	# Apply movement
	move_and_slide()

func _handle_player_input(delta: float):
	if is_ai_controlled:
		return
	
	# Get input direction
	var input_direction = Vector3.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.z = Input.get_axis("move_forward", "move_backward")
	
	# Debug input
	if input_direction.length() > 0:
		print("Input detected: ", input_direction)
	
	# Apply movement with acceleration/deceleration
	if input_direction != Vector3.ZERO:
		input_direction = input_direction.normalized()
		velocity.x = move_toward(velocity.x, input_direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, input_direction.z * SPEED, ACCELERATION * delta)
		
		print("Player velocity: ", velocity)
		
		# Player rotation - make player face movement direction
		var target_direction = Vector3(input_direction.x, 0, input_direction.z)
		if target_direction.length() > 0.1:  # Only rotate if there's significant movement
			
			if USE_LOOK_AT_ROTATION:
				# Alternative rotation method using look_at
				var target_position = global_position + target_direction
				var current_transform = global_transform
				look_at(target_position, Vector3.UP)
				# Smoothly interpolate to avoid snapping
				global_transform = current_transform.interpolate_with(global_transform, ROTATION_SPEED * delta)
			else:
				# Original rotation method using atan2
				var target_rotation = atan2(target_direction.x, target_direction.z)
				var current_rotation = rotation.y
				
				# Smooth rotation interpolation
				var angle_diff = target_rotation - current_rotation
				
				# Handle angle wrapping (shortest path)
				if angle_diff > PI:
					angle_diff -= 2 * PI
				elif angle_diff < -PI:
					angle_diff += 2 * PI
				
				# Apply smooth rotation
				var new_rotation = current_rotation + angle_diff * ROTATION_SPEED * delta
				rotation.y = new_rotation
		
		# Update animation controller with movement
		if animation_controller:
			animation_controller.set_moving(true, velocity)
		else:
			# Fallback to old animation system
			if current_animation_state != "run":
				current_animation_state = "run"
				_play_running_animation()
	else:
		# More gentle deceleration when no input
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)
		
		# Update animation controller with no movement
		if animation_controller:
			animation_controller.set_moving(false, velocity)
		else:
			# Fallback to old animation system
			if current_animation_state != "idle":
				current_animation_state = "idle"
			_play_idle_animation()

func _handle_kick_system(delta: float):
	if is_ai_controlled or kick_cooldown > 0:
		return
	
	# Check for instant kick (single press)
	if Input.is_action_just_pressed("kick"):
		print("Instant kick attempt...")
		kick_power = 0.5  # Default kick power for instant kicks
		_execute_kick()
		kick_cooldown = 0.5  # Short cooldown for instant kicks
		return
	
	# Kick charging (hold and release for power kick)
	if Input.is_action_pressed("kick"):
		if not is_charging_kick:
			is_charging_kick = true
			kick_power = 0.0
			print("Started charging kick...")
		
		kick_power = min(kick_power + delta / kick_charge_time, 1.0)
		
		# Visual feedback during charge
		_apply_kick_charge_effect()
	
	# Execute charged kick on release
	elif Input.is_action_just_released("kick") and is_charging_kick:
		print("Executing charged kick...")
		_execute_kick()
		is_charging_kick = false
		kick_power = 0.0
		
		# Reset visual feedback
		_reset_visual_effects()

func _execute_kick():
	print("=== KICK ATTEMPT ===")
	if not kick_area:
		print("Cannot kick: kick area not ready")
		return
	
	print("Kick area position: ", kick_area.global_position)
	print("Player position: ", global_position)
	print("Kick area collision_mask: ", kick_area.collision_mask)
	
	# Use both signal-based detection AND real-time check for more reliability
	var real_time_balls = kick_area.get_overlapping_bodies()
	print("Balls in kick range (signal-based): ", balls_in_kick_range.size())
	print("Balls in kick range (real-time): ", real_time_balls.size())
	
	# Try signal-based detection
	for ball in balls_in_kick_range:
		if is_instance_valid(ball) and ball.is_in_group("ball"):
			print("Ball detected via signals! Kicking...")
			_play_kick_animation()
			_kick_ball(ball)
			kick_cooldown = 0.3 + (kick_power * 0.7)
			print("Kick executed successfully!")
			return
	
	# Fallback to real-time detection
	for body in real_time_balls:
		if body.is_in_group("ball") and body is RigidBody3D:
			print("Ball detected via real-time check! Kicking...")
			_play_kick_animation()
			_kick_ball(body)
			kick_cooldown = 0.3 + (kick_power * 0.7)
			print("Kick executed successfully!")
			return
	
	print("No balls detected in kick range")
	print("=== END KICK ATTEMPT ===")

func _kick_ball(ball: RigidBody3D):
	# Calculate kick direction and force
	var kick_direction = _calculate_kick_direction(ball)
	var kick_force = _calculate_kick_force()
	
	# Use enhanced ball physics if available
	if ball.has_method("apply_kick_force"):
		# Calculate contact point for spin effects
		var contact_point = _calculate_contact_point(ball)
		ball.apply_kick_force(kick_direction, kick_power, contact_point)
	else:
		# Fallback to basic physics
		ball.linear_velocity = Vector3.ZERO  # Reset previous velocity
		ball.apply_central_impulse(kick_direction * kick_force)
		
		# Add basic spin
		var spin_force = _calculate_spin_force(ball, kick_direction)
		ball.angular_velocity += spin_force
	
	print("Player kicked ball with power: %.2f" % kick_power)

func _calculate_contact_point(ball: RigidBody3D) -> Vector3:
	# Calculate where on the ball the player's foot makes contact
	var ball_to_player = (global_position - ball.global_position).normalized()
	var ball_radius = 0.11  # Standard soccer ball radius
	
	# Contact point is on the ball surface closest to player
	var contact_point = ball.global_position + ball_to_player * ball_radius
	
	# Add some variation based on kick angle and player position
	var kick_angle_variation = Vector3(
		sin(rotation.y) * 0.05,
		0,
		cos(rotation.y) * 0.05
	)
	
	return contact_point + kick_angle_variation

func _calculate_kick_direction(ball: RigidBody3D) -> Vector3:
	var base_direction = (ball.global_position - global_position).normalized()
	base_direction.y = 0.2  # Slight upward angle
	
	# Add movement influence
	if velocity.length() > 0.1:
		var movement_influence = velocity.normalized() * 0.3
		base_direction = (base_direction + movement_influence).normalized()
	
	# Add accuracy variation
	var accuracy_factor = 1.0 - (kick_power * (1.0 - kick_accuracy))
	var random_offset = Vector3(
		randf_range(-0.1, 0.1),
		0,
		randf_range(-0.1, 0.1)
	) * (1.0 - accuracy_factor)
	
	return (base_direction + random_offset).normalized()

func _calculate_kick_force() -> float:
	var base_force = lerp(min_kick_force, max_kick_force, kick_power)
	return base_force

func _calculate_spin_force(ball: RigidBody3D, kick_direction: Vector3) -> Vector3:
	var contact_offset = ball.global_position - kick_area.global_position
	var spin = kick_direction.cross(contact_offset) * kick_power * 2.0
	return spin

func _play_running_animation():
	if animation_player and animation_player.has_animation("run"):
		if animation_player.current_animation != "run":
			animation_player.play("run")
	else:
		if not animation_warnings_shown.get("run", false):
			print("GUIDANCE: Running animation not found - need to create 'run' animation")
			animation_warnings_shown["run"] = true

func _play_idle_animation():
	if animation_player and animation_player.has_animation("idle"):
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
	else:
		if not animation_warnings_shown.get("idle", false):
			print("GUIDANCE: Idle animation not found - need to create 'idle' animation")
			animation_warnings_shown["idle"] = true

func _play_kick_animation():
	# Use new animation controller if available
	if animation_controller:
		animation_controller.trigger_kick(kick_power)
	elif animation_player and animation_player.has_animation("kick"):
		animation_player.play("kick")
	else:
		if not animation_warnings_shown.get("kick", false):
			print("GUIDANCE: Kick animation not found - need to create 'kick' animation")
			animation_warnings_shown["kick"] = true

func _apply_kick_charge_effect():
	# TODO: Add visual feedback for kick charging (particle effects, model scaling, etc.)
	pass

func _reset_visual_effects():
	# TODO: Reset any visual effects after kick
	pass

func _remove_ball_from_range(body):
	if body in balls_in_kick_range:
		balls_in_kick_range.erase(body)
		print("Ball removed from kick range. Total balls: ", balls_in_kick_range.size())

func _apply_team_colors():
	# Apply team color to uniform parts
	var uniform_color = player_team_color
	
	if chest_mesh and chest_mesh.material_override:
		chest_mesh.material_override.albedo_color = uniform_color
	if pelvis_mesh and pelvis_mesh.material_override:
		pelvis_mesh.material_override.albedo_color = uniform_color * 0.8  # Slightly darker for shorts
	if left_upper_leg_mesh and left_upper_leg_mesh.material_override:
		left_upper_leg_mesh.material_override.albedo_color = uniform_color * 0.8
	if right_upper_leg_mesh and right_upper_leg_mesh.material_override:
		right_upper_leg_mesh.material_override.albedo_color = uniform_color * 0.8

func _handle_ai_logic(_delta: float):
	# Basic AI logic (can be expanded)
	pass

func _on_kick_area_body_entered(body):
	print("Body entered kick area: ", body.name, " Groups: ", body.get_groups())
	
	if body.is_in_group("ball") and body is RigidBody3D:
		if body not in balls_in_kick_range:
			balls_in_kick_range.append(body)
			ball_detection_timer = 0.1  # Small delay for stability
		print("Ball added to kick range. Total balls: ", balls_in_kick_range.size())

func _on_kick_area_body_exited(body):
	print("Body exited kick area: ", body.name)
	
	if body.is_in_group("ball") and body in balls_in_kick_range:
		# Use call_deferred to avoid removing during physics processing
		call_deferred("_remove_ball_from_range", body)

func set_ai_controlled(ai_controlled: bool):
	is_ai_controlled = ai_controlled
	if is_ai_controlled:
		player_team_color = Color.RED
	else:
		player_team_color = Color.BLUE
	_apply_team_colors()

func set_player_color(color: Color):
	player_team_color = color
	_apply_team_colors()
