extends RigidBody3D
class_name Ball3D

# Referências
@onready var mesh_instance := $MeshInstance3D
@onready var collision_shape := $CollisionShape3D

# Propriedades da bola
var initial_position: Vector3
var max_speed: float = GameConstants.BALL_MAX_SPEED

func _ready():
	setup_ball()
	setup_physics()
	
	# Guardar posição inicial
	initial_position = global_position

func setup_ball():
	# Configurar mesh esférica
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = GameConstants.BALL_RADIUS
	sphere_mesh.height = GameConstants.BALL_RADIUS * 2
	mesh_instance.mesh = sphere_mesh
	
	# Material da bola
	var material = StandardMaterial3D.new()
	material.albedo_color = GameConstants.BALL_COLOR
	material.roughness = 0.3
	material.metallic = 0.1
	mesh_instance.material_override = material

func setup_physics():
	# Configurar collision shape
	var shape = SphereShape3D.new()
	shape.radius = GameConstants.BALL_RADIUS
	collision_shape.shape = shape
	
	# Configurar propriedades físicas
	mass = GameConstants.BALL_MASS
	gravity_scale = GameConstants.BALL_GRAVITY_SCALE
	linear_damp = GameConstants.BALL_LINEAR_DAMP
	angular_damp = GameConstants.BALL_ANGULAR_DAMP
	
	# Configurar material físico
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = GameConstants.BALL_BOUNCE
	physics_material.friction = GameConstants.BALL_FRICTION
	physics_material_override = physics_material
	
	# Configurar camadas de colisão
	collision_layer = GameConstants.LAYER_BALL
	collision_mask = GameConstants.MASK_BALL

func _physics_process(_delta):
	limit_speed()
	check_bounds()

func limit_speed():
	# Limitar velocidade máxima da bola
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func check_bounds():
	# Verificar se a bola saiu dos limites do campo
	var pos = global_position
	
	# Limites do campo
	var field_min_x = -50.0
	var field_max_x = GameConstants.FIELD_WIDTH + 50.0
	var field_min_z = -50.0
	var field_max_z = GameConstants.FIELD_DEPTH + 50.0
	
	# Se a bola saiu dos limites, resetar posição
	if pos.x < field_min_x or pos.x > field_max_x or pos.z < field_min_z or pos.z > field_max_z:
		reset_position()

func reset_position():
	# Resetar bola para o centro do campo
	global_position = Vector3(GameConstants.FIELD_WIDTH / 2, GameConstants.BALL_RADIUS + 5, GameConstants.FIELD_DEPTH / 2)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	print("Bola resetada para o centro do campo")

func apply_kick_force(direction: Vector3, force: float):
	# Aplicar força de chute à bola
	apply_central_impulse(direction.normalized() * force)

func _on_body_entered(body):
	# Detectar colisões com gols ou outros objetos
	if body.is_in_group("goals") and body is Area3D:
		handle_goal_collision(body)

func handle_goal_collision(goal_node: Area3D): # Especificar o tipo do parâmetro
	# Lógica para quando a bola entra no gol
	print("Bola entrou na Area3D do gol: ", goal_node.name)
	# Emitir um sinal para o gerenciador do jogo
	emit_signal("goal_scored_signal", goal_node.name)

signal goal_scored_signal(goal_name: String)
