extends Node

# Controlador de mecânicas avançadas baseadas em física

class_name AdvancedPhysicsController

# Configurações de mecânicas
const CURVE_SHOT_STRENGTH := 0.3
const BACKSPIN_STRENGTH := 0.5
const POWER_SHOT_MULTIPLIER := 1.5
const CHIP_SHOT_HEIGHT := 300.0
const VOLLEY_BONUS := 1.3

# Tipos de chute
enum KickType {
	NORMAL,
	POWER,
	CURVE_LEFT,
	CURVE_RIGHT,
	CHIP,
	VOLLEY,
	BICYCLE,
	HEADER
}

# Calcular física avançada do chute
func calculate_advanced_kick(
	player: CharacterBody2D,
	ball: RigidBody2D,
	input_vector: Vector2,
	kick_type: KickType
) -> Dictionary:
	
	var result = {
		"force": Vector2.ZERO,
		"spin": 0.0,
		"height_impulse": 0.0,
		"effects": []
	}
	
	# Direção base do chute
	var kick_direction = (ball.global_position - player.global_position).normalized()
	
	# Modificar direção baseado no input
	if input_vector.length() > 0:
		# Peso do input vs direção natural (permite mais controle)
		kick_direction = (kick_direction * 0.3 + input_vector.normalized() * 0.7).normalized()
	
	# Força base
	var player_speed = player.velocity.length()
	var speed_factor = remap(player_speed, 0, GameConstants.PLAYER_SPRINT_SPEED, 0.5, 1.0)
	var base_force = lerp(GameConstants.KICK_FORCE_MIN, GameConstants.KICK_FORCE_MAX, speed_factor)
	
	# Aplicar modificadores baseados no tipo de chute
	match kick_type:
		KickType.POWER:
			base_force *= POWER_SHOT_MULTIPLIER
			result.effects.append("power")
			
		KickType.CURVE_LEFT:
			result.spin = -CURVE_SHOT_STRENGTH
			kick_direction = kick_direction.rotated(-0.2)
			result.effects.append("curve_left")
			
		KickType.CURVE_RIGHT:
			result.spin = CURVE_SHOT_STRENGTH
			kick_direction = kick_direction.rotated(0.2)
			result.effects.append("curve_right")
			
		KickType.CHIP:
			kick_direction.y -= 0.5
			result.height_impulse = CHIP_SHOT_HEIGHT
			base_force *= 0.7
			result.effects.append("chip")
			
		KickType.VOLLEY:
			if not player.is_on_floor():
				base_force *= VOLLEY_BONUS
				result.effects.append("volley")
				
		KickType.BICYCLE:
			if not player.is_on_floor() and player.velocity.y < 0:
				base_force *= 1.8
				kick_direction.y -= 0.3
				result.spin = randf_range(-0.5, 0.5)
				result.effects.append("bicycle")
				
		KickType.HEADER:
			if not player.is_on_floor():
				# Cabeceio direcional
				kick_direction = input_vector.normalized() if input_vector.length() > 0 else kick_direction
				base_force *= 0.8
				result.effects.append("header")
	
	# Adicionar randomização sutil para realismo
	kick_direction = kick_direction.rotated(randf_range(-0.05, 0.05))
	
	result.force = kick_direction * base_force
	
	# Bônus por timing perfeito
	if is_perfect_timing(player, ball):
		result.force *= 1.2
		result.effects.append("perfect_timing")
	
	return result

# Detectar timing perfeito
func is_perfect_timing(player: CharacterBody2D, ball: RigidBody2D) -> bool:
	var relative_velocity = ball.linear_velocity - player.velocity
	var approach_speed = relative_velocity.dot(-(ball.global_position - player.global_position).normalized())
	
	# Timing perfeito quando a bola está se aproximando na velocidade certa
	return approach_speed > 100 and approach_speed < 300

# Sistema de controle avançado da bola
func apply_ball_control(player: CharacterBody2D, ball: RigidBody2D, control_strength: float):
	var distance = player.global_position.distance_to(ball.global_position)
	
	if distance < 50: # Raio de controle
		# Magnetismo sutil
		var pull_direction = (player.global_position - ball.global_position).normalized()
		var pull_force = (50 - distance) * control_strength * 10
		
		# Aplicar força de controle
		ball.apply_central_force(pull_direction * pull_force)
		
		# Reduzir velocidade da bola para melhor controle
		ball.linear_velocity *= 0.95
		
		return true
	return false

# Física de parede (wall physics)
func calculate_wall_bounce(ball: RigidBody2D, wall_normal: Vector2) -> void:
	# Ângulo de incidência
	var incident_angle = ball.linear_velocity.angle_to(wall_normal)
	
	# Modificar spin baseado no ângulo
	var spin_transfer = sin(incident_angle) * 0.3
	
	if ball.has_meta("spin"):
		ball.set_meta("spin", ball.get_meta("spin") + spin_transfer)

# Sistema de drible avançado
func apply_advanced_dribble(player: CharacterBody2D, ball: RigidBody2D, skill_level: float = 1.0):
	var distance = player.global_position.distance_to(ball.global_position)
	
	if distance < 40:
		# Manter bola próxima com física
		var target_offset = player.velocity.normalized() * 30
		if target_offset.length() < 1:
			target_offset = Vector2(0, -30) # Frente do jogador
		
		var target_pos = player.global_position + target_offset
		var to_target = (target_pos - ball.global_position)
		
		# Força proporcional à distância
		var force = to_target * 20 * skill_level
		ball.apply_central_force(force)
		
		# Reduzir damping para movimento mais suave
		ball.linear_damp = 2.0
		
		# Adicionar rotação à bola baseada no movimento
		if player.velocity.length() > 50:
			ball.angular_velocity = -player.velocity.x * 0.02

# Colisões jogador-jogador melhoradas
func handle_player_collision(player1: CharacterBody2D, player2: CharacterBody2D):
	var collision_vector = (player2.global_position - player1.global_position).normalized()
	var relative_velocity = player1.velocity - player2.velocity
	var collision_strength = relative_velocity.length()
	
	# Empurrão baseado em massa e velocidade
	var push_force = collision_vector * collision_strength * 0.5
	
	# Aplicar forças opostas
	player1.velocity -= push_force
	player2.velocity += push_force
	
	# Chance de queda se colisão forte
	if collision_strength > 400:
		trigger_player_stumble(player2 if relative_velocity.dot(collision_vector) > 0 else player1)

# Sistema de tropeço/queda
func trigger_player_stumble(player: CharacterBody2D):
	# Desabilitar controle temporariamente
	player.set_physics_process(false)
	
	# Animação de queda
	var tween = player.create_tween()
	tween.tween_property(player, "rotation", randf_range(-0.5, 0.5), 0.2)
	tween.tween_property(player, "rotation", 0, 0.3)
	tween.tween_callback(func(): player.set_physics_process(true))

# Cálculo de trajetória para IA ou preview
func calculate_trajectory(start_pos: Vector2, initial_velocity: Vector2, gravity: float, time_step: float = 0.1, max_points: int = 30) -> PackedVector2Array:
	var points = PackedVector2Array()
	var pos = start_pos
	var vel = initial_velocity
	
	for i in range(max_points):
		points.append(pos)
		vel.y += gravity * time_step
		pos += vel * time_step
		
		# Parar se atingir o chão
		if pos.y > GameConstants.FIELD_HEIGHT - 20:
			break
	
	return points

# Sistema de física do vento (para modo especial)
var wind_force := Vector2.ZERO
var wind_variation := 0.0

func update_wind(delta: float):
	# Vento variável
	wind_variation += delta
	wind_force = Vector2(
		sin(wind_variation * 0.5) * 50,
		cos(wind_variation * 0.3) * 20
	)

func apply_wind_to_ball(ball: RigidBody2D):
	if wind_force.length() > 0:
		ball.apply_central_force(wind_force * 0.1)

# Detecção de skill moves
func detect_skill_move(input_history: Array) -> String:
	# Analisar últimos inputs para detectar padrões
	if input_history.size() < 3:
		return ""
	
	# Exemplo: Roulette (360 spin)
	var total_rotation = 0.0
	for i in range(1, input_history.size()):
		var prev = input_history[i-1]
		var curr = input_history[i]
		if prev.length() > 0.5 and curr.length() > 0.5:
			total_rotation += prev.angle_to(curr)
	
	if abs(total_rotation) > TAU * 0.8:
		return "roulette"
	
	# Exemplo: Step over (movimento rápido L-R ou R-L)
	if input_history.size() >= 2:
		var last_two = [input_history[-2], input_history[-1]]
		if last_two[0].x * last_two[1].x < -0.8: # Direções opostas
			return "stepover"
	
	return ""

# Criar efeito visual para skill move
func create_skill_move_effect(player: CharacterBody2D, move_name: String):
	match move_name:
		"roulette":
			# Criar trail circular
			var trail = Line2D.new()
			trail.width = 5.0
			trail.default_color = Color(1, 1, 0, 0.5)
			trail.z_index = 1
			player.add_child(trail)
			
			# Animar círculo
			for i in range(32):
				var angle = i * TAU / 32
				var point = Vector2(cos(angle), sin(angle)) * 30
				trail.add_point(point)
				await player.get_tree().create_timer(0.01).timeout
			
			# Fade out
			var tween = player.create_tween()
			tween.tween_property(trail, "modulate:a", 0.0, 0.3)
			tween.tween_callback(trail.queue_free)
			
		"stepover":
			# Após-imagem
			var ghost = player.sprite.duplicate()
			player.get_parent().add_child(ghost)
			ghost.global_position = player.global_position
			ghost.modulate.a = 0.5
			
			var tween = player.create_tween()
			tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
			tween.tween_callback(ghost.queue_free)