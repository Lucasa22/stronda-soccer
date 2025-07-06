extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.5
const KICK_FORCE = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var player_mesh = $PlayerMesh
@onready var kick_area_3d = $KickArea3D

var look_direction = Vector3.FORWARD

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): # "ui_accept" is usually Spacebar
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # Mapped to WASD/Arrows
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_direction = direction # Update look direction when moving
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# Rotate mesh to face movement direction (simple rotation, can be smoothed later)
	if direction:
		player_mesh.look_at(global_position + direction, Vector3.UP)

	# Handle Kick
	if Input.is_action_just_pressed("kick"): # Assuming "kick" action is mapped
		_handle_kick()

func _handle_kick():
	var bodies = kick_area_3d.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("ball"): # Make sure Ball3D is added to "ball" group
			var kick_dir = (body.global_position - global_position).normalized()
			# Apply a slight upward angle to the kick
			kick_dir.y = 0.2
			kick_dir = kick_dir.normalized()

			body.apply_central_impulse(kick_dir * KICK_FORCE)
			print("Kicked ball!")

func set_player_name(new_name):
	var label = $PlayerNameLabel3D
	if label:
		label.text = new_name

func set_player_color(color: Color):
	if player_mesh and player_mesh.get_surface_material_count() > 0:
		var mat = player_mesh.get_surface_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = color
		else: # If it's not a StandardMaterial3D, create one
			var new_mat = StandardMaterial3D.new()
			new_mat.albedo_color = color
			player_mesh.set_surface_material(0, new_mat)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Default color if not set otherwise
	set_player_color(Color.BLUE_VIOLET)
	# Add to player group for potential interactions
	add_to_group("players")


# Input mapping (ensure these are set up in Project > Project Settings > Input Map)
# "move_forward" (W, Up Arrow)
# "move_backward" (S, Down Arrow)
# "move_left" (A, Left Arrow)
# "move_right" (D, Right Arrow)
# "kick" (e.g., E, Mouse Click)
# "ui_accept" (Space for jump)
