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
	
	# Garantir que o jogador possa responder a inputs diretos
	set_process_input(true)
	
	# Verificar se o script está recebendo inputs corretamente
	print("Player3D inicializado e pronto para receber inputs")
	print("Pressione a tecla K para chutar")
	
	# Procurar o AnimationPlayer se ele existir na cena
	var animation_player = find_child("AnimationPlayer")
	if animation_player:
		print("AnimationPlayer encontrado")
	else:
		print("AVISO: AnimationPlayer não encontrado")
		
	# Verificar e corrigir camadas de colisão
	print("Layer de colisão atual: ", collision_layer)
	print("Mask de colisão atual: ", collision_mask)
	
	# Adicionar a camada da bola (layer 4) ao mask de colisão se não estiver presente
	if not (collision_mask & 4): # Verifica se o bit 4 está definido
		print("Adicionando layer da bola (4) ao mask de colisão")
		collision_mask |= 4 # Adiciona o bit 4 (layer da bola) ao mask

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
	
	# Certifique-se de que o player pode colidir com as bolas (layer 4)
	collision_mask = GameConstants.MASK_PLAYER | 4 # Adiciona o bit 4 (layer da bola)
	
	# Criar um kick_area para detecção mais precisa
	add_kick_area_if_needed()

func _physics_process(delta):
	handle_movement(delta)
	handle_kick_cooldown(delta)
	
	# Adicionar detecção direta de input para chute
	if Input.is_action_just_pressed("kick") and can_kick:
		print("Tecla K detectada em _physics_process!")
		attempt_kick()
	
	# Aplicar física
	move_and_slide()

func handle_movement(delta):
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y -= GameConstants.GRAVITY * delta
	
	# Input de movimento (será controlado pelo script principal)
	var current_speed = sprint_speed if is_sprinting else move_speed

	# Obter a câmera para movimento relativo
	var camera = get_viewport().get_camera_3d()
	var target_velocity = Vector3.ZERO

	if camera:
		var camera_basis = camera.global_transform.basis
		var forward = -camera_basis.z.normalized()
		var right = camera_basis.x.normalized()

		# O input_vector.z é para frente/trás, input_vector.x é para esquerda/direita
		target_velocity += input_vector.z * forward
		target_velocity += input_vector.x * right
		target_velocity.y = 0 # Manter o movimento no plano XZ

		if target_velocity.length_squared() > 0: # Normalizar apenas se houver input
			target_velocity = target_velocity.normalized() * current_speed
	else:
		# Fallback para movimento não relativo à câmera se a câmera não for encontrada
		target_velocity.x = input_vector.x * current_speed
		target_velocity.z = input_vector.z * current_speed

	# Suavização de movimento (aceleração/desaceleração)
	var acceleration_factor = 10.0 # Ajuste este valor conforme necessário
	velocity.x = lerp(velocity.x, target_velocity.x, delta * acceleration_factor)
	velocity.z = lerp(velocity.z, target_velocity.z, delta * acceleration_factor)
	
	# Pulo
	if input_vector.y > 0 and is_on_floor(): # input_vector.y é usado para o sinal de pulo
		velocity.y = jump_velocity
	
	# Aplicar fricção no chão (quando não há input de movimento horizontal)
	if is_on_floor() and target_velocity.length_squared() == 0 and input_vector.x == 0 and input_vector.z == 0:
		var stop_friction = friction * 2 # Pode ser uma fricção maior para parar mais rápido
		velocity.x = move_toward(velocity.x, 0, stop_friction * delta)
		velocity.z = move_toward(velocity.z, 0, stop_friction * delta)
	elif is_on_floor(): # Fricção normal se houver input mas não máximo
		velocity.x = move_toward(velocity.x, target_velocity.x, friction * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, friction * delta)


func handle_kick_cooldown(delta):
	if kick_cooldown_timer > 0:
		kick_cooldown_timer -= delta
		can_kick = false
	else:
		can_kick = true
		
	# Debug: verificar se a tecla K está sendo reconhecida pelo sistema
	if Input.is_action_just_pressed("kick"):
		print("DEBUG: Tecla K detectada em handle_kick_cooldown!")

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
	
	print("Tentando chutar, distância até a bola:", global_position.distance_to(ball.global_position))
	
	# Aumentar temporariamente o KICK_RANGE para facilitar o chute
	var kick_range_expanded = GameConstants.KICK_RANGE * 2.0
	var distance_to_ball = global_position.distance_to(ball.global_position)
	
	if distance_to_ball <= kick_range_expanded:
		print("Bola dentro do alcance, executando chute!")
		kick_ball()
	else:
		print("Bola fora de alcance:", distance_to_ball, " > ", kick_range_expanded)

func kick_ball():
	if not ball:
		print("ERRO: Não foi possível chutar - referência à bola é nula")
		return
	
	if not can_kick:
		print("ERRO: Não foi possível chutar - em cooldown")
		return
	
	print("--- INICIANDO CHUTE ---")
	
	# Calcular direção e força do chute
	var kick_direction = (ball.global_position - global_position).normalized()
	kick_direction.y += GameConstants.KICK_UPWARD_MODIFIER
	kick_direction = kick_direction.normalized()
	
	print("Direção do chute: ", kick_direction)
	
	# Aplicar força à bola
	var kick_force = randf_range(GameConstants.KICK_FORCE_MIN, GameConstants.KICK_FORCE_MAX)
	print("Força do chute: ", kick_force)
	
	# Verificar se a bola tem os métodos necessários
	if not ball.has_method("apply_central_impulse"):
		print("ERRO: A bola não tem o método apply_central_impulse!")
		return
	
	# Aplicar o impulso
	ball.apply_central_impulse(kick_direction * kick_force)
	print("Impulso aplicado à bola!")
	
	# Iniciar cooldown
	kick_cooldown_timer = GameConstants.KICK_COOLDOWN
	can_kick = false
	
	print("Player %s chutou a bola!" % player_name)
	
	# Tocar animação de chute se disponível
	var animation_player = get_node_or_null("AnimationPlayer")
	if animation_player and animation_player.has_animation("kick"):
		animation_player.play("kick")
		print("Animação 'kick' executada")
	else:
		print("Aviso: Animação 'kick' não encontrada, usando feedback visual alternativo")

	# Feedback visual simples para chute: piscar a cor
	var original_color = player_color
	mesh_instance.material_override.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if mesh_instance and mesh_instance.material_override: # Verificar se ainda existe
		mesh_instance.material_override.albedo_color = original_color
	
	print("--- CHUTE CONCLUÍDO ---")

func set_ball_reference(ball_ref: RigidBody3D):
	ball = ball_ref
	print("Bola referenciada com sucesso: ", ball.name)
	print("Posição da bola: ", ball.global_position)
	print("Grupos da bola: ", ball.get_groups())
	
	# Verificar se a bola está no grupo "ball" - necessário para detecção
	if not ball.is_in_group("ball"):
		print("AVISO: A bola não está no grupo 'ball', adicionando...")
		ball.add_to_group("ball")

func set_team_color(color: Color):
	player_color = color
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = color

func _input(event):
	# Detectar pressionar da tecla K para chute diretamente
	if event.is_action_pressed("kick") and can_kick:
		print("Tecla K detectada diretamente!")
		attempt_kick()

func add_kick_area_if_needed():
	# Verificar se já existe uma área de chute
	var existing_kick_area = find_child("KickArea3D")
	if existing_kick_area:
		print("Área de chute já existe")
		return
	
	print("Criando área de chute...")
	
	# Criar uma nova área de chute
	var kick_area = Area3D.new()
	kick_area.name = "KickArea3D"
	kick_area.collision_layer = 0 # Não queremos que outros objetos colidam com ela
	kick_area.collision_mask = 4  # Apenas detectar bolas (layer 4)
	add_child(kick_area)
	
	# Criar uma forma de colisão para a área
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = GameConstants.KICK_RANGE * 1.5 # Um pouco maior que o alcance de chute
	collision_shape.shape = sphere_shape
	kick_area.add_child(collision_shape)
	
	# Posicionar a área em frente ao jogador
	kick_area.position = Vector3(0, 0, -GameConstants.PLAYER_SIZE_3D.z)
	
	print("Área de chute criada com sucesso, radius:", sphere_shape.radius)
	
	# Conectar sinais para depuração
	kick_area.body_entered.connect(_on_kick_area_body_entered)
	kick_area.body_exited.connect(_on_kick_area_body_exited)
	
	return kick_area

func _on_kick_area_body_entered(body):
	print("Corpo entrou na área de chute:", body.name)
	if body.is_in_group("ball"):
		print("Bola detectada dentro da área de chute!")

func _on_kick_area_body_exited(body):
	print("Corpo saiu da área de chute:", body.name)
	if body.is_in_group("ball"):
		print("Bola saiu da área de chute!")
