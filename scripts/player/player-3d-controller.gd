extends CharacterBody3D
class_name Player3D

# Referências
@onready var mesh_instance := $MeshInstance3D
@onready var collision_shape := $CollisionShape3D
@onready var label_3d := $Label3D

# Propriedades do jogador
var player_id: int = 0
var team: int = 1
var player_name: String = "Player"
var player_color: Color = Color.BLUE

# Estado do jogador
var move_speed: float = GameConstants.PLAYER_MOVE_SPEED
var sprint_speed: float = GameConstants.PLAYER_SPRINT_SPEED
var jump_velocity: float = GameConstants.PLAYER_JUMP_VELOCITY
var friction: float = GameConstants.PLAYER_FRICTION

# Controles
var input_vector: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var can_kick: bool = true
var kick_cooldown_timer: float = 0.0

# Referência à bola
var ball: RigidBody3D = null

func _ready():
	setup_player()
	setup_collision()

func setup_player():
	# Configurar visual do jogador
	var box_mesh = BoxMesh.new()
	box_mesh.size = GameConstants.PLAYER_SIZE_3D
	mesh_instance.mesh = box_mesh
	
	# Material do jogador
	var material = StandardMaterial3D.new()
	material.albedo_color = player_color
	mesh_instance.material_override = material
	
	# Configurar label
	label_3d.text = player_name
	label_3d.position = Vector3(0, GameConstants.PLAYER_HEIGHT + 10, 0)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func setup_collision():
	# Configurar collision shape
	var shape = BoxShape3D.new()
	shape.size = GameConstants.PLAYER_SIZE_3D
	collision_shape.shape = shape
	
	# Configurar camadas de colisão
	collision_layer = GameConstants.LAYER_PLAYERS
	collision_mask = GameConstants.MASK_PLAYER

func _physics_process(delta):
	handle_movement(delta)
	handle_kick_cooldown(delta)
	
	# Aplicar física
	move_and_slide()

func handle_movement(delta):
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y -= GameConstants.GRAVITY * delta
	
	# Input de movimento (será controlado pelo script principal)
	var current_speed = sprint_speed if is_sprinting else move_speed
	velocity.x = input_vector.x * current_speed
	velocity.z = input_vector.z * current_speed
	
	# Pulo
	if input_vector.y > 0 and is_on_floor():
		velocity.y = jump_velocity
	
	# Aplicar fricção no chão
	if is_on_floor() and input_vector.length() == 0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

func handle_kick_cooldown(delta):
	if kick_cooldown_timer > 0:
		kick_cooldown_timer -= delta
		can_kick = false
	else:
		can_kick = true

func set_input(input_dir: Vector3, sprint: bool = false, jump: bool = false, kick: bool = false):
	input_vector = input_dir
	is_sprinting = sprint
	
	if jump:
		input_vector.y = 1.0
	else:
		input_vector.y = 0.0
	
	if kick and can_kick:
		attempt_kick()

func attempt_kick():
	if not ball or not can_kick:
		return
	
	var distance_to_ball = global_position.distance_to(ball.global_position)
	if distance_to_ball <= GameConstants.KICK_RANGE:
		kick_ball()

func kick_ball():
	if not ball or not can_kick:
		return
	
	# Calcular direção e força do chute
	var kick_direction = (ball.global_position - global_position).normalized()
	kick_direction.y += GameConstants.KICK_UPWARD_MODIFIER
	kick_direction = kick_direction.normalized()
	
	# Aplicar força à bola
	var kick_force = randf_range(GameConstants.KICK_FORCE_MIN, GameConstants.KICK_FORCE_MAX)
	ball.apply_central_impulse(kick_direction * kick_force)
	
	# Iniciar cooldown
	kick_cooldown_timer = GameConstants.KICK_COOLDOWN
	can_kick = false
	
	print("Player %s chutou a bola!" % player_name)

func set_ball_reference(ball_ref: RigidBody3D):
	ball = ball_ref

func set_team_color(color: Color):
	player_color = color
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = color
