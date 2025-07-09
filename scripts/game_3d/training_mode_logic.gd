extends Node

@export var player_node_path: NodePath
@export var ball_node_path: NodePath

var player:		else:
			push_warning("Training Mode: Player node is null, cannot reset position.")haracterBody3D
var ball: RigidBody3D
var ai_player: CharacterBody3D
var goal1_area: Area3D
var goal2_area: Area3D
var ui_label: Label

# Score tracking
var player_score: int = 0
var ai_score: int = 0

# Define initial positions (can be customized or made into export vars)
var initial_player_position: Vector3 = Vector3(0, -0.035, 8)
var initial_ball_position: Vector3 = Vector3(0, 0.6, 0)
var center_field_ball_position: Vector3 = Vector3(0, 0.6, 0)


func _ready():
	if player_node_path:
		player = get_node_or_null(player_node_path)
	if ball_node_path:
		ball = get_node_or_null(ball_node_path)

	# Get AI player
	ai_player = get_node_or_null("Players/AIPlayer1")

	# Get goal areas
	goal1_area = get_node_or_null("Goal1_Area3D")
	goal2_area = get_node_or_null("Goal2_Area3D")
	ui_label = get_node_or_null("UI/InfoLabel")

	if not player:
		push_warning("Training Mode: Player node not found at path: " + str(player_node_path))
	if not ball:
		push_warning("Training Mode: Ball node not found at path: " + str(ball_node_path))

	# Configure AI player
	if ai_player and ai_player.has_method("set_ai_controlled"):
		ai_player.set_ai_controlled(true)
		ai_player.set_player_color(Color.RED)
		print("AI Player configured successfully")

	# Connect goal signals
	if goal1_area:
		goal1_area.body_entered.connect(_on_goal1_entered)
	if goal2_area:
		goal2_area.body_entered.connect(_on_goal2_entered)

	# Update UI
	update_ui()

	# Set initial positions when mode starts (optional, player/ball might be placed by scene already)
	# reset_player_position()
	# reset_ball_position(center_field_ball_position)


func _unhandled_input(event):
	if event.is_action_pressed("reset_ball"):
		if is_instance_valid(ball):
			reset_ball_position(center_field_ball_position)
			print("Ball position reset to center field.")
		else:
			push_warning("Training Mode: Cannot reset ball, instance is invalid.")

	if event.is_action_pressed("reset_player"): # Assuming you might want a separate reset for player
		if is_instance_valid(player):
			reset_player_position()
			print("Player position reset.")
		else:
			push_warning("Training Mode: Cannot reset player, instance is invalid.")

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
			push_warning("Training Mode: Ball node is null, cannot reset position.")


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

func _on_goal1_entered(body):
	if body == ball:
		player_score += 1
		print("GOAL! Player scored! Score: Player %d - %d AI" % [player_score, ai_score])
		update_ui()
		reset_after_goal()

func _on_goal2_entered(body):
	if body == ball:
		ai_score += 1
		print("GOAL! AI scored! Score: Player %d - %d AI" % [player_score, ai_score])
		update_ui()
		reset_after_goal()

func reset_after_goal():
	await get_tree().create_timer(2.0).timeout
	reset_ball_position()
	reset_player_position()

func update_ui():
	if ui_label:
		ui_label.text = "Training Mode - Score: Player %d - %d AI
WASD: Move, Space: Jump, F: Kick
R: Reset Ball" % [player_score, ai_score]
