extends Node

# Test script to verify kick system works
var player: CharacterBody3D
var ball: RigidBody3D

func _ready():
	print("Starting kick system test...")
	call_deferred("run_test")

func run_test():
	# Get references
	player = get_node("/root/TrainingModeSimple/Players/Player1")
	ball = get_node("/root/TrainingModeSimple/BallContainer/Ball")
	
	if player and ball:
		print("Player found: ", player.name)
		print("Ball found: ", ball.name)
		print("Ball groups: ", ball.get_groups())
		print("Ball collision_layer: ", ball.collision_layer)
		
		# Move player closer to ball
		player.global_position = ball.global_position + Vector3(-0.5, 0, 0)
		print("Player moved to: ", player.global_position)
		print("Ball position: ", ball.global_position)
		
		# Wait briefly then test kick
		await get_tree().process_frame
		await get_tree().process_frame
		test_kick()
	else:
		print("Could not find player or ball")

func test_kick():
	print("Testing kick system...")
	
	# Get kick area and test directly
	var kick_area = player.kick_area
	if kick_area:
		print("Kick area position: ", kick_area.global_position)
		print("Kick area collision settings - layer: ", kick_area.collision_layer, " mask: ", kick_area.collision_mask)
		
		var overlapping = kick_area.get_overlapping_bodies()
		print("Overlapping bodies: ", overlapping.size())
		for body in overlapping:
			print("  - Body: ", body.name, " Groups: ", body.get_groups(), " Layer: ", body.collision_layer)
	
	# Simulate kick execution
	player.is_charging_kick = true
	player.kick_power = 0.8
	
	# Execute kick
	player._execute_kick()
	player.is_charging_kick = false
	player.kick_power = 0.0
	
	# Check ball velocity after kick
	await get_tree().process_frame
	print("Ball velocity after kick: ", ball.linear_velocity)
	
	print("Test completed")
	get_tree().quit()
