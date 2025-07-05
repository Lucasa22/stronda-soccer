extends CharacterBody2D

# Identificação do jogador
@export var player_id := 0
@export var team := 0
@export var player_color := Color.WHITE
var input_map := {}

# Estados do jogador
enum State { GROUND, AIR }
var current_state := State.GROUND

# Variáveis de movimento
var input_vector := Vector2.ZERO
var is_sprinting := false
var can_double_jump := true
var kick_cooldown := 0.0

# Visual
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var kick_area := $KickArea
@onready var name_label := $NameLabel
@onready var arrow_indicator := $ArrowIndicator

func _ready():
	# Configurar camadas de colisão
	collision_layer = GameConstants.LAYER_PLAYERS
	collision_mask = GameConstants.LAYER_WALLS | GameConstants.LAYER_PLAYERS
	
	# Configurar visual
	setup_visual()
	
	# Adicionar ao grupo
	add_to_group("players")
	add_to_group("team_%d" % team)

func setup_visual():
	# Cor do jogador
	if sprite:
		sprite.modulate = player_color
	
	# Nome do jogador
	if name_label:
		name_label.text = "P%d" % (player_id + 1)
		name_label.modulate = player_color
	
	# Indicador de seta (para identificar jogador)
	if arrow_indicator:
		arrow_indicator.modulate = player_color
		arrow_indicator.position.y = -40

func _physics_process(delta):
	# Processar input específico do jogador
	handle_player_input()
	
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
	if is_action_just_pressed("kick") and kick_cooldown <= 0:
		kick_ball()
	
	# Mover e detectar colisões
	move_and_slide()
	
	# Atualizar visual
	update_sprite()
	update_indicators()

func handle_player_input():
	# Input específico por jogador
	input_vector = Vector2.ZERO
	
	# Teclado ou Gamepad
	if "device" in input_map:
		# Gamepad
		var device = input_map["device"]
		input_vector.x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		input_vector.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		
		# Deadzone
		if input_vector.length() < 0.2:
			input_vector = Vector2.ZERO
		else:
			input_vector = input_vector.normalized()
	else:
		# Teclado
		input_vector.x = get_axis("move_left", "move_right")
		input_vector.y = get_axis("move_up", "move_down")
		input_vector = input_vector.normalized()
	
	# Sprint
	is_sprinting = is_action_pressed("sprint")

func get_axis(negative_action: String, positive_action: String) -> float:
	var neg = -1.0 if is_action_pressed(negative_action) else 0.0
	var pos = 1.0 if is_action_pressed(positive_action) else 0.0
	return neg + pos

func is_action_pressed(action: String) -> bool:
	if not action in input_map:
		return false
	
	var mapped_action = input_map[action]
	
	if "device" in input_map:
		# Gamepad
		match action:
			"jump":
				return Input.is_joy_button_pressed(input_map["device"], JOY_BUTTON_A)
			"kick":
				return Input.is_joy_button_pressed(input_map["device"], JOY_BUTTON_X)
			"sprint":
				return Input.is_joy_button_pressed(input_map["device"], JOY_BUTTON_RIGHT_SHOULDER)
	else:
		# Teclado
		return Input.is_action_pressed(mapped_action)
	
	return false

func is_action_just_pressed(action: String) -> bool:
	if not action in input_map:
		return false
	
	var mapped_action = input_map[action]
	
	if "device" in input_map:
		# Gamepad
		match action:
			"jump":
				return Input.is_joy_button_pressed(input_map["device"], JOY_BUTTON_A)
			"kick":
				return Input.is_joy_button_pressed(input_map["device"], JOY_BUTTON_X)
	else:
		# Teclado
		return Input.is_action_just_pressed(mapped_action)
	
	return false

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
	if is_action_just_pressed("jump"):
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
				body.last_touched_by = self
			
			# Cooldown
			kick_cooldown = GameConstants.KICK_COOLDOWN
			
			# Feedback visual
			create_kick_feedback()
			
			break

func create_kick_feedback():
	modulate = Color.WHITE * 1.5
	create_tween().tween_property(self, "modulate", player_color, 0.1)
	
	# Vibração do gamepad
	if "device" in input_map:
		Input.start_joy_vibration(input_map["device"], 0.5, 0.5, 0.2)

func update_sprite():
	# Flip sprite baseado na direção
	if input_vector.x != 0:
		sprite.flip_h = input_vector.x < 0
	
	# Animações simples
	if current_state == State.AIR:
		sprite.modulate = player_color * 0.9
	else:
		sprite.modulate = player_color

func update_indicators():
	# Mostrar/esconder indicador baseado no movimento
	if arrow_indicator:
		arrow_indicator.visible = input_vector.length() < 0.1
		if arrow_indicator.visible:
			# Animar seta flutuando
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(arrow_indicator, "position:y", -45, 0.5)
			tween.tween_property(arrow_indicator, "position:y", -35, 0.5)

func celebrate_goal():
	# Animação de celebração
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "rotation", TAU, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_property(self, "rotation", 0, 0.1)
