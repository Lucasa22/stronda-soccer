extends Node3D

@export var player_node_path: NodePath
@export var ball_node_path: NodePath

var player: CharacterBody3D
var ball: RigidBody3D
var goal_area: Area3D
var ui_label: Label

# Score tracking
var player_score: int = 0

func _ready():
	# Wait for scene to be fully ready
	call_deferred("setup_nodes")

func setup_nodes():
	print("Setting up nodes...")
	
	if player_node_path:
		player = get_node_or_null(player_node_path)
		print("Player path: ", player_node_path, " Found: ", player != null)
	if ball_node_path:
		ball = get_node_or_null(ball_node_path)
		print("Ball path: ", ball_node_path, " Found: ", ball != null)

	# Get goal area
	goal_area = get_node_or_null("Goal_Area3D")
	ui_label = get_node_or_null("UI/InfoLabel")

	if not player:
		print("Training Mode: Player node not found")
	if not ball:
		print("Training Mode: Ball node not found")

	# Connect goal signal
	if goal_area:
		goal_area.body_entered.connect(_on_goal_entered)
		print("Goal area connected successfully")

	# Update UI
	update_ui()

func _unhandled_input(event):
	if event.is_action_pressed("reset_ball"):
		if ball:
			reset_ball_position()
			print("Ball position reset to center field.")

func reset_ball_position():
	if ball:
		ball.global_position = Vector3(0, 0.11, 0)
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO

func _on_goal_entered(body):
	if body == ball:
		player_score += 1
		print("GOAL! Player scored! Total goals: %d" % player_score)
		update_ui()
		reset_after_goal()

func reset_after_goal():
	await get_tree().create_timer(2.0).timeout
	reset_ball_position()
	if player:
		player.global_position = Vector3(0, 1, 3)
		player.velocity = Vector3.ZERO

func update_ui():
	if ui_label:
		ui_label.text = "Training Mode - Goals: %d
WASD: Move, Space: Jump, F: Kick
R: Reset Ball" % player_score
