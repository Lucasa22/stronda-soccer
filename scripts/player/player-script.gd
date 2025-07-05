extends CharacterBody2D

# Estados do jogador
enum State { GROUND, AIR }
var current_state := State.GROUND

# Variáveis de movimento
var input_vector := Vector2.ZERO
var is_sprinting := false
var can_double_jump := true
var kick_cooldown := 0.0

# Referências
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var kick_area := $KickArea

func _ready():
	# Configurar camadas de colisão
	collision_layer = GameConstants.LAYER_PLAYERS
	collision_mask = GameConstants.LAYER_WALLS | GameConstants.LAYER_PLAYERS

func _physics_process(delta):
	# Processar input
	handle_input()
	
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		current_state = State.AIR
	else:
		current_state = State.GROUND
		can_double_jump = true
	
	# Aplicar movimento horizontal
	apply_movement(delta)
	
	# Processar salto
	handle_jump()
	
	# Atualizar cooldown do chute
	if kick_cooldown > 0:
		kick_cooldown -= delta
	
	# Processar chute
	if Input.is_action_just_pressed("kick") and kick_cooldown <= 0:
		kick_ball()
	
	# Mover e detectar colisões
	move_and_slide()
	
	# Atualizar visual
	update_sprite()

func handle_input():
	# Capturar input direcional
	input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	input_vector = input_vector.normalized()
	
	# Sprint
	is_sprinting = Input.is_action_pressed("sprint")

func apply_movement(delta):
	var target_speed = GameConstants.PLAYER_SPRINT_SPEED if is_sprinting else GameConstants.PLAYER_MOVE_SPEED
	
	# Movimento horizontal
	if input_vector.x != 0:
		if current_state == State.GROUND:
			velocity.x = move_toward(velocity.x, input_vector.x * target_speed, GameConstants.PLAYER_FRICTION * target_speed * delta)
		else:
			# Controle aéreo reduzido
			velocity.x = move_toward(velocity.x, input_vector.x * target_speed, GameConstants.PLAYER_AIR_CONTROL * target_speed * delta)
	else:
		# Aplicar fricção quando não há input
		if current_state == State.GROUND:
			velocity.x = move_toward(velocity.x, 0, GameConstants.PLAYER_FRICTION * target_speed * delta)

func handle_jump():
	if Input.is_action_just_pressed("jump"):
		if current_state == State.GROUND:
			velocity.y = GameConstants.PLAYER_JUMP_VELOCITY
		elif can_double_jump:
			velocity.y = GameConstants.PLAYER_JUMP_VELOCITY * 0.8
			can_double_jump = false

func kick_ball():
	# Detectar bolas na área de chute
	var balls = kick_area.get_overlapping_bodies()
	
	for body in balls:
		if body.is_in_group("ball"):
			# Calcular direção e força do chute
			var kick_direction = (body.global_position - global_position).normalized()
			
			# Adicionar influência da direção do input
			if input_vector.length() > 0:
				kick_direction = (kick_direction + input_vector).normalized()
			
			# Calcular força baseada na velocidade do jogador
			var speed_factor = velocity.length() / GameConstants.PLAYER_SPRINT_SPEED
			var kick_force = lerp(GameConstants.KICK_FORCE_MIN, GameConstants.KICK_FORCE_MAX, speed_factor)
			
			# Adicionar componente vertical se estiver no ar
			if current_state == State.AIR:
				kick_direction.y -= GameConstants.KICK_UPWARD_MODIFIER
			
			# Aplicar força à bola
			if body.has_method("receive_kick"):
				body.receive_kick(kick_direction * kick_force, global_position)
			
			# Cooldown
			kick_cooldown = GameConstants.KICK_COOLDOWN
			
			# Feedback visual (placeholder)
			modulate = Color.WHITE * 1.5
			create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
			
			break # Chutar apenas uma bola por vez

func update_sprite():
	# Flip sprite baseado na direção
	if input_vector.x != 0:
		sprite.flip_h = input_vector.x < 0
	
	# Animações simples (placeholder)
	if current_state == State.AIR:
		sprite.modulate = Color(0.9, 0.9, 1.0)
	else:
		sprite.modulate = Color.WHITE
