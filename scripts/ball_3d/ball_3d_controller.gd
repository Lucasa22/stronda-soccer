extends RigidBody3D

# Ball properties - Enhanced physics system
@export var base_mass: float = 0.45  # Official soccer ball mass in kg
@export var base_radius: float = 0.11  # Official soccer ball radius in meters
@export var air_resistance: float = 0.02  # Air resistance factor
@export var ground_friction: float = 0.7  # Ground friction coefficient
@export var bounce_damping: float = 0.8  # Energy loss on bounce
@export var spin_decay: float = 0.95  # How quickly spin decreases
@export var max_spin_force: float = 5.0  # Maximum spin force

# Physics state variables
var current_surface_type: String = "grass"  # grass, concrete, etc.
var is_being_dribbled: bool = false
var spin_vector: Vector3 = Vector3.ZERO
var last_impact_velocity: Vector3 = Vector3.ZERO
var ground_contact_timer: float = 0.0

# Default physics values
var _default_linear_damp: float = 0.1
var _default_angular_damp: float = 0.1

# Surface physics properties
var surface_properties: Dictionary = {
	"grass": {
		"friction": 0.7,
		"bounce": 0.6,
		"roll_resistance": 0.3
	},
	"concrete": {
		"friction": 0.9,
		"bounce": 0.8,
		"roll_resistance": 0.1
	},
	"mud": {
		"friction": 1.2,
		"bounce": 0.3,
		"roll_resistance": 0.8
	}
}

func _ready():
	print("Ball3D: Starting enhanced physics system")
	
	# Add to "ball" group for easier identification
	add_to_group("ball")
	print("Ball3D: Added to ball group")
	
	# Set collision layers - Ball is on layer 2 (LAYER_BALL)
	collision_layer = GameConstants.LAYER_BALL  # Ball layer (2)
	collision_mask = GameConstants.MASK_BALL  # Collide with players, walls, goals, and ground
	print("Ball3D: Collision layers set")
	
	# Set up enhanced physics properties
	mass = base_mass
	
	# Initialize physics material if not set
	if not physics_material_override:
		var physics_mat = PhysicsMaterial.new()
		physics_mat.friction = surface_properties[current_surface_type]["friction"]
		physics_mat.bounce = surface_properties[current_surface_type]["bounce"]
		physics_material_override = physics_mat
	
	# Store default damp values
	_default_linear_damp = linear_damp if linear_damp > 0 else 0.1
	_default_angular_damp = angular_damp if angular_damp > 0 else 0.1
	
	# Enable physics processing
	set_physics_process(true)
	print("Ball3D: Enhanced physics system initialized")

func _physics_process(delta: float):
	# Apply enhanced physics effects
	apply_air_resistance(delta)
	apply_spin_effects(delta)
	apply_surface_effects(delta)
	
	# Update ground contact detection
	update_ground_contact(delta)
	
	# Decay spin over time
	spin_vector *= spin_decay
	
	# Update angular velocity based on spin
	if spin_vector.length() > 0.1:
		angular_velocity = spin_vector

func apply_air_resistance(_delta: float):
	# Apply air resistance based on velocity
	var velocity_magnitude = linear_velocity.length()
	if velocity_magnitude > 0.1:
		var resistance_force = -linear_velocity.normalized() * air_resistance * velocity_magnitude * velocity_magnitude
		apply_central_force(resistance_force)

func apply_spin_effects(_delta: float):
	# Magnus effect - spin affects trajectory
	if spin_vector.length() > 0.1 and linear_velocity.length() > 1.0:
		var magnus_force = spin_vector.cross(linear_velocity) * 0.1
		apply_central_force(magnus_force)

func apply_surface_effects(delta: float):
	# Apply different effects based on surface contact
	if is_on_ground():
		var surface_props = surface_properties[current_surface_type]
		var roll_resistance = surface_props["roll_resistance"]
		
		# Apply rolling resistance
		if linear_velocity.length() > 0.1:
			var resistance = -linear_velocity.normalized() * roll_resistance * mass * 9.81 * delta
			apply_central_force(resistance)

func update_ground_contact(delta: float):
	# Check if ball is on ground using raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position, 
		global_position + Vector3(0, -base_radius - 0.1, 0),
		collision_mask
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		ground_contact_timer = 0.0
		# TODO: Detect surface type based on collision object
		current_surface_type = "grass"  # Default for now
	else:
		ground_contact_timer += delta

func is_on_ground() -> bool:
	return ground_contact_timer < 0.1

func apply_kick_force(kick_direction: Vector3, kick_power: float, contact_point: Vector3 = Vector3.ZERO):
	"""Enhanced kick system with realistic physics response"""
	
	# Calculate base force based on kick power
	var base_force = kick_power * 25.0  # Adjust multiplier as needed
	
	# Apply some randomness for realism
	var accuracy_factor = 1.0 - (1.0 - 0.85) * randf()  # 85% base accuracy
	var direction_variation = Vector3(
		randf_range(-0.1, 0.1),
		randf_range(-0.05, 0.05),
		randf_range(-0.1, 0.1)
	) * (1.0 - accuracy_factor)
	
	var final_direction = (kick_direction + direction_variation).normalized()
	var final_force = base_force * accuracy_factor
	
	# Apply the kick force
	linear_velocity = Vector3.ZERO  # Reset current velocity
	apply_central_impulse(final_direction * final_force)
	
	# Calculate and apply spin based on contact point
	if contact_point != Vector3.ZERO:
		var spin_direction = calculate_spin_from_contact(contact_point, final_direction)
		spin_vector = spin_direction * kick_power * max_spin_force
		angular_velocity = spin_vector
	
	# Store impact data
	last_impact_velocity = linear_velocity
	
	print("Ball kicked: Force=%.2f, Direction=%s, Spin=%s" % [final_force, final_direction, spin_vector])

func calculate_spin_from_contact(contact_point: Vector3, kick_direction: Vector3) -> Vector3:
	"""Calculate spin based on where the ball was contacted"""
	# Contact point relative to ball center
	var contact_offset = contact_point - global_position
	
	# Calculate spin direction based on contact point
	var spin_axis = contact_offset.cross(kick_direction).normalized()
	var spin_intensity = contact_offset.length() / base_radius
	
	return spin_axis * spin_intensity

func apply_bounce_effect(collision_normal: Vector3, collision_velocity: Vector3):
	"""Enhanced bounce physics"""
	var surface_props = surface_properties[current_surface_type]
	var bounce_factor = surface_props["bounce"] * bounce_damping
	
	# Calculate bounce velocity
	var bounce_velocity = collision_velocity.bounce(collision_normal) * bounce_factor
	
	# Apply spin effects on bounce
	if spin_vector.length() > 0.1:
		var spin_effect = spin_vector.cross(collision_normal) * 0.3
		bounce_velocity += spin_effect
	
	# Update velocity
	linear_velocity = bounce_velocity
	
	# Reduce spin on impact
	spin_vector *= 0.7
	
	print("Ball bounced: Velocity=%s, Spin=%s" % [bounce_velocity, spin_vector])

func reset_ball_physics():
	"""Reset ball to default physics state"""
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	spin_vector = Vector3.ZERO
	ground_contact_timer = 0.0
	current_surface_type = "grass"
	
	print("Ball physics reset")

# Enhanced dribbling system
func set_is_being_dribbled(dribbling_status: bool):
	is_being_dribbled = dribbling_status
	
	if is_being_dribbled:
		# Reduce damping for more responsive dribbling
		linear_damp = _default_linear_damp * 0.1
		angular_damp = _default_angular_damp * 0.1
		# Reduce air resistance during dribbling
		air_resistance *= 0.5
	else:
		# Restore normal physics
		linear_damp = _default_linear_damp
		angular_damp = _default_angular_damp
		air_resistance = 0.02  # Reset to default
	
	print("Ball dribbling status: %s" % dribbling_status)

# Surface detection and adaptation
func change_surface_type(new_surface: String):
	if new_surface in surface_properties:
		current_surface_type = new_surface
		
		# Update physics material
		if physics_material_override:
			var surface_props = surface_properties[current_surface_type]
			physics_material_override.friction = surface_props["friction"]
			physics_material_override.bounce = surface_props["bounce"]
		
		print("Ball surface changed to: %s" % new_surface)
	else:
		print("Warning: Unknown surface type: %s" % new_surface)

# Collision detection for enhanced effects
func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		print("Ball contacted player")
	elif body.is_in_group("goal"):
		print("Ball entered goal!")
	elif body.is_in_group("wall"):
		print("Ball hit wall")

func _integrate_forces(state: PhysicsDirectBodyState3D):
	# Custom physics integration for advanced effects
	
	# Apply Magnus effect more precisely
	if spin_vector.length() > 0.1 and linear_velocity.length() > 1.0:
		var magnus_force = spin_vector.cross(linear_velocity) * 0.15 * mass
		state.apply_central_force(magnus_force)
	
	# Apply custom gravity modifications if needed
	# (e.g., for different ball types or environmental effects)
	
	# Handle collision responses
	for i in range(state.get_contact_count()):
		var contact_normal = state.get_contact_local_normal(i)
		var contact_velocity = state.get_contact_local_velocity_at_position(i)
		
		# Enhanced bounce calculation
		if contact_velocity.length() > 2.0:  # Significant impact
			apply_bounce_effect(contact_normal, contact_velocity)
