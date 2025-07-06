extends Node

@export var player_node_path: NodePath
@export var ball_node_path: NodePath

var player: CharacterBody3D
var ball: RigidBody3D

# Define initial positions (can be customized or made into export vars)
var initial_player_position: Vector3 = Vector3(0, 1, 8)
var initial_ball_position: Vector3 = Vector3(0, 0.5, 2)
var center_field_ball_position: Vector3 = Vector3(0, 0.5, 0)


func _ready():
	if player_node_path:
		player = get_node_or_null(player_node_path)
	if ball_node_path:
		ball = get_node_or_null(ball_node_path)

	if not player:
		print_warning("Training Mode: Player node not found at path: ", player_node_path)
	if not ball:
		print_warning("Training Mode: Ball node not found at path: ", ball_node_path)

	# Set initial positions when mode starts (optional, player/ball might be placed by scene already)
	# reset_player_position()
	# reset_ball_position(center_field_ball_position)


func _unhandled_input(event):
	if event.is_action_pressed("reset_ball"):
		if is_instance_valid(ball):
			reset_ball_position(center_field_ball_position)
			print("Ball position reset to center field.")
		else:
			print_warning("Training Mode: Cannot reset ball, instance is invalid.")

	if event.is_action_pressed("reset_player"): # Assuming you might want a separate reset for player
		if is_instance_valid(player):
			reset_player_position()
			print("Player position reset.")
		else:
			print_warning("Training Mode: Cannot reset player, instance is invalid.")

func reset_ball_position(position: Vector3 = center_field_ball_position):
	if is_instance_valid(ball):
		ball.global_transform.origin = position
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
	else:
		# Attempt to re-acquire if null and path is set
		if ball_node_path: ball = get_node_or_null(ball_node_path)
		if is_instance_valid(ball):
			ball.global_transform.origin = position
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO
		else:
			print_warning("Training Mode: Ball node is null, cannot reset position.")


func reset_player_position(position: Vector3 = initial_player_position):
	if is_instance_valid(player):
		player.global_transform.origin = position
		player.velocity = Vector3.ZERO # Reset player's internal velocity if applicable
	else:
		# Attempt to re-acquire
		if player_node_path: player = get_node_or_null(player_node_path)
		if is_instance_valid(player):
			player.global_transform.origin = position
			player.velocity = Vector3.ZERO
		else:
			print_warning("Training Mode: Player node is null, cannot reset position.")


# Ensure "reset_ball" and "reset_player" (if used) actions are defined in Project Settings > Input Map.
# For "reset_ball", map it to 'R' key.
# For "reset_player", you can map it to something like Shift+R or another key.
