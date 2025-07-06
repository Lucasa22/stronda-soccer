extends RigidBody3D

# Ball properties
# Mass, friction, bounce can be set here or in the Inspector via PhysicsMaterialOverride

func _ready():
	# Add to "ball" group for easier identification (e.g., by player's kick area)
	add_to_group("ball")

	# Physics material properties are now primarily set in the Inspector for Ball3D.tscn.
	# This script won't override them unless specific dynamic adjustments are needed.
	# If you need to access them:
	# var current_material = physics_material_override
	# if current_material:
	#	 current_material.friction = new_friction_value
	# else:
	#	 var new_material = PhysicsMaterial.new()
	#	 new_material.friction = 0.4 # Default if somehow not set
	#	 new_material.bounce = 0.7  # Default if somehow not set
	#	 physics_material_override = new_material

	# print("Ball ready. Mass: ", mass, " Friction: ", physics_material_override.friction if physics_material_override else "N/A", " Bounce: ", physics_material_override.bounce if physics_material_override else "N/A")

# Variable to be set by player when dribbling, to temporarily modify physics
var is_being_dribbled: bool = false
var _default_linear_damp: float = -1.0 # Store project default or inspector value
var _default_angular_damp: float = -1.0

func _ready():
	add_to_group("ball")
	# Store default damp values if not already set by inspector override
	if linear_damp < 0:
		_default_linear_damp = ProjectSettings.get_setting("physics/3d/default_linear_damp", 0.1)
	else:
		_default_linear_damp = linear_damp

	if angular_damp < 0:
		_default_angular_damp = ProjectSettings.get_setting("physics/3d/default_angular_damp", 0.1)
	else:
		_default_angular_damp = angular_damp

	if _default_linear_damp < 0: _default_linear_damp = 0.1
	if _default_angular_damp < 0: _default_angular_damp = 0.1

	set_physics_process_internal(true) # Ensure _integrate_forces is called

func set_is_being_dribbled(dribbling_status: bool):
	is_being_dribbled = dribbling_status
	# Immediately update damping when status changes
	if is_being_dribbled:
		linear_damp = _default_linear_damp * 0.1 # Significantly reduce for responsiveness
		angular_damp = _default_angular_damp * 0.1
	else:
		linear_damp = _default_linear_damp
		angular_damp = _default_angular_damp

func _integrate_forces(state):
	if is_being_dribbled:
		# Lower damping when being dribbled for more responsiveness to player's forces
		linear_damp = default_linear_damp * 0.2
		angular_damp = default_angular_damp * 0.2
	else:
		# Restore default damping when not being dribbled
		linear_damp = default_linear_damp
		angular_damp = default_angular_damp

		# Apply custom drag if the ball is in the air (simple air resistance)
		# Only apply this when not being actively dribbled to avoid interference
		if not state.get_contact_count() > 0:
			var air_resistance_factor = 0.015 # Slightly increased
			state.linear_velocity -= state.linear_velocity * air_resistance_factor * state.step

	# Could add Magnus effect here if desired
	pass


@onready var collision_sound: AudioStreamPlayer3D = $CollisionSound if has_node("CollisionSound") else null

func _on_body_entered(body):
	# print("Ball collided with: ", body.name)
	if collision_sound and collision_sound.stream:
		if not collision_sound.is_playing():
			var impact_speed = linear_velocity.length()
			# Adjust volume and pitch based on impact speed for more dynamic sound
			var volume_factor = clamp(impact_speed / 20.0, 0.2, 1.0) # Max volume at speed 20+
			collision_sound.volume_db = linear_to_db(volume_factor) - 5 # Adjust base volume offset
			collision_sound.pitch_scale = randf_range(0.9, 1.1) * clamp(impact_speed / 15.0, 0.8, 1.2)
			collision_sound.play()

	# Example: if it hits a player, maybe a different sound or logic
	# if body.is_in_group("players"):
		# print("Ball hit a player")
	pass

# func _on_ball_screen_exited():
	# This function would be connected to the VisibleOnScreenNotifier3D's screen_exited signal
	# print("Ball is off-screen. Resetting or removing.")
	# queue_free() # Or reset its position, etc.
	# Example: global_position = Vector3.ZERO
	# linear_velocity = Vector3.ZERO
	# angular_velocity = Vector3.ZERO
	# get_tree().call_group("game_manager", "reset_ball_position", self) # If a game manager handles this
	# pass
