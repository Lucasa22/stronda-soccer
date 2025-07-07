extends CharacterBody3D

# Player movement constants
const SPEED = 7.0
const JUMP_VELOCITY = 12.0
const ACCELERATION = 15.0
const DECELERATION = 20.0

# Player properties
@export var player_team_color: Color = Color.BLUE
@export var is_ai_controlled: bool = false

# Realistic kick system variables
@export var min_kick_force: float = 3.0
@export var max_kick_force: float = 25.0
@export var kick_charge_time: float = 1.2
@export var kick_accuracy: float = 0.85
var kick_power: float = 0.0
var is_charging_kick: bool = false
var kick_cooldown: float = 0.0

# References to modular components
@onready var player_model: Node3D = $PlayerModel
@onready var label_3d: Label3D = $PlayerNameLabel3D

var kick_area: Area3D

# Team color materials
var chest_mesh: MeshInstance3D
var pelvis_mesh: MeshInstance3D
var left_upper_leg_mesh: MeshInstance3D
var right_upper_leg_mesh: MeshInstance3D

func _ready():
	# Set collision layers
	collision_layer = 1
	collision_mask = 1 | 4 | 8
	add_to_group("players")
	
	# Setup kick area with deferred call
	call_deferred("setup_kick_area")
	
	# Apply team colors
	call_deferred("_apply_team_colors")
	
	print("Modular Player initialized at position: ", global_position)
	print("Player ", name, " is AI controlled: ", is_ai_controlled)

func setup_kick_area():
	kick_area = get_node_or_null("PlayerModel/Pelvis/RightHip/RightUpperLeg/RightLowerLeg/RightFoot/KickArea3D")
	if kick_area:
		print("Kick area found successfully")
		print("Kick area collision_layer: ", kick_area.collision_layer)
		print("Kick area collision_mask: ", kick_area.collision_mask)
		# Connect signals for debugging
		kick_area.body_entered.connect(_on_kick_area_body_entered)
		kick_area.body_exited.connect(_on_kick_area_body_exited)
	else:
		print("Warning: Kick area not found")
	
	# Setup mesh references
	chest_mesh = get_node_or_null("PlayerModel/Pelvis/Spine/Chest/ChestMesh")
	pelvis_mesh = get_node_or_null("PlayerModel/Pelvis/PelvisMesh")
	left_upper_leg_mesh = get_node_or_null("PlayerModel/Pelvis/LeftHip/LeftUpperLeg/LeftUpperLegMesh")
	right_upper_leg_mesh = get_node_or_null("PlayerModel/Pelvis/RightHip/RightUpperLeg/RightUpperLegMesh")

func _physics_process(delta: float):
	# Update cooldowns
	if kick_cooldown > 0:
		kick_cooldown -= delta
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if velocity.y < 0:
			velocity.y = 0

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
	
	# Apply movement with acceleration/deceleration
	if input_direction != Vector3.ZERO:
		input_direction = input_direction.normalized()
		velocity.x = move_toward(velocity.x, input_direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, input_direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

func _handle_kick_system(delta: float):
	if is_ai_controlled or kick_cooldown > 0:
		return
	
	# Kick charging
	if Input.is_action_pressed("kick"):
		if not is_charging_kick:
			is_charging_kick = true
			kick_power = 0.0
			print("Started charging kick...")
		
		kick_power = min(kick_power + delta / kick_charge_time, 1.0)
		
		# Visual feedback during charge
		_apply_kick_charge_effect()
	
	# Execute kick on release
	elif Input.is_action_just_released("kick") and is_charging_kick:
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
	
	var balls_in_range = kick_area.get_overlapping_bodies()
	print("Bodies in kick range: ", balls_in_range.size())
	
	for body in balls_in_range:
		print("Body found: ", body.name, " Type: ", body.get_class(), " Groups: ", body.get_groups())
		print("Body collision_layer: ", body.collision_layer)
		if body.is_in_group("ball"):
			print("Ball detected! Kicking...")
			_kick_ball(body)
			
			# Set cooldown based on kick power
			kick_cooldown = 0.3 + (kick_power * 0.7)
			print("Kick executed successfully!")
			return
		else:
			print("Body is not in 'ball' group")
	
	if balls_in_range.size() == 0:
		print("No bodies detected in kick area")
	print("=== END KICK ATTEMPT ===")

func _kick_ball(ball: RigidBody3D):
	# Calculate kick direction and force
	var kick_direction = _calculate_kick_direction(ball)
	var kick_force = _calculate_kick_force()
	
	# Apply physics to ball
	ball.linear_velocity = Vector3.ZERO  # Reset previous velocity
	ball.apply_central_impulse(kick_direction * kick_force)
	
	# Add spin based on contact point
	var spin_force = _calculate_spin_force(ball, kick_direction)
	ball.angular_velocity += spin_force
	
	print("Player kicked ball with power: %.2f" % (kick_force / max_kick_force))

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

func _apply_kick_charge_effect():
	# Scale effect during charge
	var scale_factor = 1.0 + (kick_power * 0.1)
	if player_model:
		player_model.scale = Vector3.ONE * scale_factor
	
	# Color effect during charge
	var charge_color = Color.WHITE.lerp(Color.YELLOW, kick_power)
	if chest_mesh and chest_mesh.material_override:
		chest_mesh.material_override.albedo_color = charge_color

func _reset_visual_effects():
	if player_model:
		player_model.scale = Vector3.ONE
	_apply_team_colors()

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

func _handle_ai_logic(delta: float):
	# Basic AI logic (can be expanded)
	pass

func _on_kick_area_body_entered(body):
	print("Body entered kick area: ", body.name, " Groups: ", body.get_groups())

func _on_kick_area_body_exited(body):
	print("Body exited kick area: ", body.name)

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
