extends RigidBody3D

# Realistic soccer ball physics
const BALL_MASS = 0.43  # FIFA regulation: 410-450g
const BALL_RADIUS = 0.11  # FIFA regulation: 21-22cm diameter
const AIR_RESISTANCE = 0.02  # Drag coefficient
const ANGULAR_DRAG = 0.95  # Spin decay factor
const GROUND_FRICTION = 0.4  # Rolling friction on grass
const BOUNCE_DAMPING = 0.6  # Energy loss on bounce

var last_velocity: Vector3 = Vector3.ZERO
var spin_velocity: Vector3 = Vector3.ZERO

func _ready():
	# Add to "ball" group for easier identification
	add_to_group("ball")
	
	# Set collision layers - Ball is on layer 4
	collision_layer = 4  # Ball layer
	collision_mask = 1 | 4 | 8  # Collide with players (1), walls (4), and goals (8)
	
	# Set realistic physics properties
	mass = BALL_MASS
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = BOUNCE_DAMPING
	physics_material.friction = GROUND_FRICTION
	physics_material_override = physics_material
	
	# Set gravity scale (ball is slightly affected by air)
	gravity_scale = 0.98

func _integrate_forces(state):
	# Apply air resistance
	if linear_velocity.length() > 0.1:
		var air_resistance_force = -linear_velocity.normalized() * linear_velocity.length_squared() * AIR_RESISTANCE
		state.apply_central_force(air_resistance_force)
	
	# Apply Magnus effect (spin affects trajectory)
	if spin_velocity.length() > 0.1 and linear_velocity.length() > 1.0:
		var magnus_force = spin_velocity.cross(linear_velocity) * 0.001
		state.apply_central_force(magnus_force)
	
	# Decay spin over time
	spin_velocity *= ANGULAR_DRAG
	
	# Ground friction when rolling
	if is_on_ground() and linear_velocity.length() < 8.0:
		var ground_friction_force = -linear_velocity * GROUND_FRICTION * 2.0
		ground_friction_force.y = 0  # Don't apply friction vertically
		state.apply_central_force(ground_friction_force)

func is_on_ground() -> bool:
	# Check if ball is close to ground (y <= radius + small margin)
	return global_position.y <= (BALL_RADIUS + 0.1)

func apply_kick_force(direction: Vector3, force: float, spin: Vector3 = Vector3.ZERO):
	# Apply the kick force
	apply_central_impulse(direction * force)
	
	# Add spin to the ball
	spin_velocity = spin
	
	# Add some random variation for realism
	var random_variation = Vector3(
		randf_range(-0.1, 0.1),
		randf_range(-0.05, 0.05),
		randf_range(-0.1, 0.1)
	)
	apply_central_impulse(random_variation * force * 0.1)
