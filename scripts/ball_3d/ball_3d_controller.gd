extends RigidBody3D

# Ball properties
# Mass, friction, bounce can be set here or in the Inspector via PhysicsMaterialOverride

func _ready():
	# Add to "ball" group for easier identification (e.g., by player's kick area)
	add_to_group("ball")

	# Example of setting physics material properties via code if not set in inspector
	if not physics_material_override:
		var new_material = PhysicsMaterial.new()
		new_material.friction = 0.5
		new_material.bounce = 0.6
		physics_material_override = new_material
	else:
		# Ensure the existing material has some default values if you want to tweak them
		# For example, if you set it in the scene but want to ensure bounce is at least 0.5
		# physics_material_override.bounce = max(physics_material_override.bounce, 0.5)
		pass

	# Optional: Apply a small initial random spin or movement for testing
	# angular_velocity = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized() * randf_range(0.5, 2.0)

func _integrate_forces(state):
	# Custom physics integration if needed, e.g., applying air resistance (Magnus effect for spin)
	# For now, standard Godot physics should be sufficient.
	pass

# Example function if you want the ball to do something specific on collision
# This requires contact_monitor to be true and max_contacts_reported > 0
# func _on_body_entered(body):
# 	print("Ball collided with: ", body.name)
# 	if body.is_in_group("players"):
# 		# Play a sound or trigger an effect
# 		pass

# func _on_ball_screen_exited():
	# This function would be connected to the VisibleOnScreenNotifier3D's screen_exited signal
	# print("Ball is off-screen. Resetting or removing.")
	# queue_free() # Or reset its position, etc.
	# Example: global_position = Vector3.ZERO
	# linear_velocity = Vector3.ZERO
	# angular_velocity = Vector3.ZERO
	# get_tree().call_group("game_manager", "reset_ball_position", self) # If a game manager handles this
	pass

@onready var collision_sound: AudioStreamPlayer3D = $CollisionSound if has_node("CollisionSound") else null

func _on_body_entered(body):
	# print("Ball collided with: ", body.name)
	if collision_sound and collision_sound.stream:
		# Play sound if it's not already playing (prevents spamming on multiple contacts in same frame)
		if not collision_sound.is_playing():
			# Optionally, vary pitch slightly for more dynamic sound
			# collision_sound.pitch_scale = randf_range(0.9, 1.1)
			collision_sound.play()

	# Example: if it hits a player, maybe a different sound or logic
	# if body.is_in_group("players"):
		# print("Ball hit a player")
		pass
