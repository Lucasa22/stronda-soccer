extends Node3D
class_name PlayerAnimationController

# Estados de animação
enum AnimationState {
	IDLE,
	RUNNING,
	SPRINTING,
	JUMPING,
	FALLING,
	LANDING,
	KICKING,
	CELEBRATING,
	SLIDING,
	TURNING
}

# Configurações de animação
@export_group("Animation Settings")
@export var run_speed_threshold: float = 0.5
@export var sprint_speed_threshold: float = 4.0
@export var turn_speed_threshold: float = 2.0
@export var landing_impact_threshold: float = 5.0
@export var animation_blend_speed: float = 10.0

# Referências
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var player_body: CharacterBody3D

# Estado atual
var current_state: AnimationState = AnimationState.IDLE
var previous_state: AnimationState = AnimationState.IDLE
var state_timer: float = 0.0

# Variáveis de controle
var is_moving: bool = false
var is_sprinting: bool = false
var is_airborne: bool = false
var is_kicking: bool = false
var kick_power: float = 0.0
var movement_speed: float = 0.0
var turn_speed: float = 0.0
var air_time: float = 0.0
var last_ground_velocity: Vector3 = Vector3.ZERO

# Blend de animações
var animation_blend_weights: Dictionary = {}
var target_blend_weights: Dictionary = {}

# Fila de animações prioritárias
var priority_queue: Array = []

# Sistema de camadas de animação
var upper_body_override: float = 0.0
var lower_body_override: float = 0.0

func _ready():
	print("PlayerAnimationController: Initializing...")
	
	# Buscar referências
	player_body = get_parent()
	animation_player = player_body.get_node_or_null("AnimationPlayer")
	
	if not animation_player:
		push_error("PlayerAnimationController: AnimationPlayer not found!")
		return
	
	# Inicializar pesos de blend
	for state in AnimationState.values():
		animation_blend_weights[state] = 0.0
		target_blend_weights[state] = 0.0
	
	# Configurar AnimationTree se existir
	_setup_animation_tree()
	
	print("PlayerAnimationController: Ready!")

func _setup_animation_tree():
	# Criar AnimationTree dinamicamente se não existir
	animation_tree = player_body.get_node_or_null("AnimationTree")
	
	if not animation_tree:
		animation_tree = AnimationTree.new()
		animation_tree.name = "AnimationTree"
		player_body.add_child(animation_tree)
		animation_tree.anim_player = animation_player.get_path()
		animation_tree.active = true
		print("PlayerAnimationController: AnimationTree created")

func _physics_process(delta: float):
	if not animation_player:
		return
	
	# Atualizar timers
	state_timer += delta
	
	# Detectar estado do jogador
	_update_player_state(delta)
	
	# Processar fila de prioridades
	_process_priority_queue()
	
	# Atualizar blend de animações
	_update_animation_blends(delta)
	
	# Aplicar animações
	_apply_animations()
	
	# Aplicar animações procedurais
	apply_procedural_lean(delta)
	apply_procedural_bounce(delta)

func _update_player_state(delta: float):
	# Verificar se está no ar
	var was_airborne = is_airborne
	is_airborne = not player_body.is_on_floor()
	
	# Detectar pouso
	if was_airborne and not is_airborne:
		_handle_landing()
	
	# Atualizar tempo no ar
	if is_airborne:
		air_time += delta
	else:
		air_time = 0.0
		last_ground_velocity = player_body.velocity
	
	# Calcular velocidade de movimento
	var horizontal_velocity = Vector3(player_body.velocity.x, 0, player_body.velocity.z)
	movement_speed = horizontal_velocity.length()
	
	# Calcular velocidade de rotação
	# (você pode implementar isso baseado na mudança de direção)
	
	# Determinar estado baseado nas condições
	_determine_animation_state()

func _determine_animation_state():
	var new_state = current_state
	
	# Prioridade das animações
	if is_kicking:
		new_state = AnimationState.KICKING
	elif is_airborne:
		if player_body.velocity.y > 0:
			new_state = AnimationState.JUMPING
		else:
			new_state = AnimationState.FALLING
	elif movement_speed > sprint_speed_threshold and is_sprinting:
		new_state = AnimationState.SPRINTING
	elif movement_speed > run_speed_threshold:
		new_state = AnimationState.RUNNING
	elif turn_speed > turn_speed_threshold:
		new_state = AnimationState.TURNING
	else:
		new_state = AnimationState.IDLE
	
	# Mudar estado se necessário
	if new_state != current_state:
		_change_state(new_state)

func _change_state(new_state: AnimationState):
	previous_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	print("Animation State Changed: %s -> %s" % [
		AnimationState.keys()[previous_state],
		AnimationState.keys()[new_state]
	])
	
	# Configurar pesos alvo para blend
	_set_target_blend_weights(new_state)
	
	# Executar lógica específica do estado
	_enter_state(new_state)

func _enter_state(state: AnimationState):
	match state:
		AnimationState.IDLE:
			_play_animation("idle", -1, 1.0)
		
		AnimationState.RUNNING:
			var anim_speed = remap(movement_speed, run_speed_threshold, sprint_speed_threshold, 0.8, 1.5)
			_play_animation("run", -1, anim_speed)
		
		AnimationState.SPRINTING:
			_play_animation("sprint", -1, 1.2)
		
		AnimationState.JUMPING:
			_play_animation("jump_start", 0.2)
			_queue_animation("jump_loop", -1, 1.0, 0.2)
		
		AnimationState.FALLING:
			_play_animation("fall_loop", -1, 1.0)
		
		AnimationState.LANDING:
			var impact_force = abs(player_body.velocity.y)
			if impact_force > landing_impact_threshold:
				_play_animation("landing_hard", 0.3)
			else:
				_play_animation("landing_soft", 0.2)
		
		AnimationState.KICKING:
			var kick_anim = _get_kick_animation_name()
			_play_animation(kick_anim, 0.6)
		
		AnimationState.TURNING:
			_play_animation("turn", -1, 1.5)

func _play_animation(anim_name: String, duration: float = -1, speed: float = 1.0, blend: float = 0.2):
	if not animation_player.has_animation(anim_name):
		push_warning("Animation '%s' not found!" % anim_name)
		return
	
	animation_player.play(anim_name, blend, speed)
	
	if duration > 0:
		_add_to_priority_queue({
			"animation": anim_name,
			"duration": duration,
			"elapsed": 0.0
		})

func _queue_animation(anim_name: String, duration: float, speed: float, delay: float):
	await get_tree().create_timer(delay).timeout
	_play_animation(anim_name, duration, speed)

func _add_to_priority_queue(anim_data: Dictionary):
	priority_queue.append(anim_data)

func _process_priority_queue():
	var completed = []
	
	for i in range(priority_queue.size()):
		var anim = priority_queue[i]
		anim.elapsed += get_physics_process_delta_time()
		
		if anim.elapsed >= anim.duration:
			completed.append(i)
	
	# Remover animações completadas
	for i in range(completed.size() - 1, -1, -1):
		priority_queue.remove_at(completed[i])

func _set_target_blend_weights(state: AnimationState):
	# Resetar todos os pesos
	for s in AnimationState.values():
		target_blend_weights[s] = 0.0
	
	# Definir peso do estado atual
	target_blend_weights[state] = 1.0
	
	# Adicionar blends especiais
	match state:
		AnimationState.RUNNING:
			# Blend suave entre idle e run baseado na velocidade
			var run_weight = remap(movement_speed, 0, run_speed_threshold, 0, 1)
			target_blend_weights[AnimationState.IDLE] = 1.0 - run_weight
			target_blend_weights[AnimationState.RUNNING] = run_weight
		
		AnimationState.TURNING:
			# Manter um pouco da animação anterior durante a rotação
			target_blend_weights[previous_state] = 0.3

func _update_animation_blends(delta: float):
	for state in AnimationState.values():
		animation_blend_weights[state] = move_toward(
			animation_blend_weights[state],
			target_blend_weights[state],
			animation_blend_speed * delta
		)

func _apply_animations():
	# Aplicar blend weights ao AnimationTree se disponível
	if animation_tree and animation_tree.active:
		# Implementar lógica do AnimationTree aqui
		pass

func _handle_landing():
	var impact_velocity = abs(last_ground_velocity.y)
	
	_change_state(AnimationState.LANDING)
	
	# Efeitos adicionais baseados no impacto
	if impact_velocity > landing_impact_threshold * 1.5:
		# Animação de recuperação pesada
		_queue_animation("recovery", 0.5, 1.0, 0.3)
		
		# Reduzir temporariamente a velocidade de movimento
		player_body.velocity *= 0.5

func _get_kick_animation_name() -> String:
	# Selecionar animação de chute baseada no contexto
	if is_airborne:
		return "kick_air"
	elif kick_power > 0.8:
		return "kick_power"
	elif movement_speed > run_speed_threshold:
		return "kick_running"
	else:
		return "kick"

# APIs públicas para o controlador do jogador
func set_moving(moving: bool, _velocity: Vector3):
	is_moving = moving
	# Atualizar outras variáveis baseadas no movimento

func set_sprinting(sprinting: bool):
	is_sprinting = sprinting

func trigger_kick(power: float):
	if is_kicking:
		return
	
	is_kicking = true
	kick_power = power
	
	# Reset após animação
	await get_tree().create_timer(0.6).timeout
	is_kicking = false
	kick_power = 0.0

func trigger_celebration(celebration_type: int = 0):
	_change_state(AnimationState.CELEBRATING)
	
	match celebration_type:
		0:
			_play_animation("celebration_fist_pump", 2.0)
		1:
			_play_animation("celebration_slide", 1.5)
		2:
			_play_animation("celebration_backflip", 1.0)

func trigger_slide():
	if current_state == AnimationState.SLIDING:
		return
	
	_change_state(AnimationState.SLIDING)
	_play_animation("slide", 0.8)

# Sistema de animação procedural
func apply_procedural_lean(delta: float):
	if not player_body.has_node("PlayerModel"):
		return
	
	var model = player_body.get_node("PlayerModel")
	
	# Inclinar o modelo baseado na velocidade lateral
	var lateral_velocity = player_body.velocity.x
	var target_lean = clamp(lateral_velocity * 0.02, -0.3, 0.3)
	
	model.rotation.z = move_toward(model.rotation.z, target_lean, 2.0 * delta)

func apply_procedural_bounce(_delta: float):
	if not player_body.has_node("PlayerModel"):
		return
	
	var model = player_body.get_node("PlayerModel")
	
	# Adicionar bounce sutil durante a corrida
	if current_state == AnimationState.RUNNING:
		var bounce_amount = sin(state_timer * 12.0) * 0.02
		model.position.y = bounce_amount

# Debug e visualização
func get_current_state_name() -> String:
	return AnimationState.keys()[current_state]

func get_animation_debug_info() -> Dictionary:
	var active_anims = []
	if animation_player:
		active_anims = [animation_player.current_animation]
	
	return {
		"current_state": get_current_state_name(),
		"movement_speed": movement_speed,
		"is_airborne": is_airborne,
		"air_time": air_time,
		"state_timer": state_timer,
		"active_animations": active_anims
	}
