extends CharacterBody2D

# Player com todas as mecânicas avançadas integradas

# Componentes
@onready var physics_controller := AdvancedPhysicsController.new()
@onready var effects_manager := $"/root/VisualEffectsManager"
@onready var audio_system := $"/root/AudioSystem"

# Visual components
@onready var sprite := $Sprite2D
@onready var shadow := $Shadow
@onready var trail := $Trail
@onready var boost_particles := $BoostParticles
@onready var skill_indicator := $SkillIndicator

# Estados avançados
enum AdvancedState { 
	NORMAL, 
	SPRINTING, 
	SLIDING, 
	SKILL_MOVE, 
	STUMBLED, 
	CELEBRATING 
}

var advanced_state := AdvancedState.NORMAL

# Mecânicas avançadas
var stamina := 100.0
var stamina_regen_rate := 20.0
var skill_move_cooldown := 0.0
var combo_timer := 0.0
var combo_count := 0
var input_history := []
var is_charging_shot := false
var charge_power := 0.0
var ball_control_skill := 1.0

# Configurações por jogador
@export var player_stats := {
	"speed": 1.0,
	"acceleration": 1.0,
	"shot_power": 1.0,
	"ball_control": 1.0,
	"stamina": 1.0
}

# Efeitos visuais
var current_height := 0.0
var visual_rotation := 0.0
var squash_stretch := Vector2.ONE
var speed_lines_active := false

func _ready():
	setup_visual_components()
	add_child(physics_controller)

func setup_visual_components():
	# Configurar sombra dinâmica
	if effects_manager:
		shadow = effects_manager.create_dynamic_shadow(self)
	
	# Trail para alta velocidade
	trail = Line2D.new()
	trail.width = 10.0
	trail.width_curve = Curve.new()
	trail.width_curve.add_point(Vector2(0, 1))
	trail.width_curve.add_point(Vector2(1, 0))
	trail.z_index = -1
	trail.show_behind_parent = true
	add_child(trail)
	
	# Configurar indicador de skill
	create_skill_indicator()

func _physics_process(delta):
	# Input e histórico
	handle_advanced_input()
	update_input_history()
	
	# Estados
	update_advanced_states(delta)
	
	# Física base
	apply_gravity(delta)
	apply_advanced_movement(delta)
	
	# Sistemas
	update_stamina(delta)
	update_combos(delta)
	
	# Interações
	if kick_cooldown > 0:
		kick_cooldown -= delta
	
	handle_advanced_kick()
	
	# Movimento final
	move_and_slide()
	
	# Visuais e áudio
	update_advanced_visuals(delta)
	update_audio_feedback()

func handle_advanced_input():
	input_vector = Vector2.ZERO
	
	# Input específico do jogador (herdado)
	if "device" in input_map:
		var device = input_map["device"]
		input_vector.x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		input_vector.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		if input_vector.length() < 0.2:
			input_vector = Vector2.ZERO
	else:
		input_vector.x = get_axis("move_left", "move_right")
		input_vector.y = get_axis("move_up", "move_down")
	
	input_vector = input_vector.normalized()
	
	# Sprint com stamina
	is_sprinting = is_action_pressed("sprint") and stamina > 10.0
	
	# Detectar carga de chute
	if is_action_pressed("kick"):
		is_charging_shot = true
		charge_power = min(charge_power + get_physics_process_delta_time() * 2.0, 1.0)
	elif is_charging_shot and not is_action_pressed("kick"):
		is_charging_shot = false

func update_input_history():
	input_history.append(input_vector)
	if input_history.size() > 10:
		input_history.pop_front()

func update_advanced_states(delta):
	match advanced_state:
		AdvancedState.SLIDING:
			# Física de deslize
			velocity *= 0.95
			if velocity.length() < 50:
				advanced_state = AdvancedState.NORMAL
				
		AdvancedState.STUMBLED:
			velocity *= 0.9
			
		AdvancedState.SKILL_MOVE:
			if skill_move_cooldown <= 0:
				advanced_state = AdvancedState.NORMAL

func apply_advanced_movement(delta):
	if advanced_state == AdvancedState.STUMBLED:
		return
	
	var base_speed = GameConstants.PLAYER_MOVE_SPEED * player_stats.speed
	var sprint_speed = GameConstants.PLAYER_SPRINT_SPEED * player_stats.speed
	var target_speed = sprint_speed if is_sprinting else base_speed
	
	# Aceleração melhorada
	var acceleration = GameConstants.PLAYER_FRICTION * player_stats.acceleration
	
	if input_vector.length() > 0:
		# Slide tackle
		if is_on_floor() and Input.is_action_just_pressed("slide"):
			perform_slide_tackle()
			return
		
		# Movimento normal/sprint
		if current_state == State.GROUND:
			velocity = velocity.move_toward(input_vector * target_speed, acceleration * target_speed * delta)
		else:
			# Controle aéreo
			velocity.x = move_toward(velocity.x, input_vector.x * target_speed, GameConstants.PLAYER_AIR_CONTROL * target_speed * delta)
	else:
		# Fricção
		if current_state == State.GROUND:
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * target_speed * delta)

func perform_slide_tackle():
	advanced_state = AdvancedState.SLIDING
	velocity = velocity.normalized() * GameConstants.PLAYER_SPRINT_SPEED * 1.5
	
	# Efeitos
	if effects_manager:
		effects_manager.create_speed_distortion(self)
	
	# Som
	if audio_system:
		audio_system.play_sound("player_slide", global_position)

func handle_advanced_kick():
	if not is_action_just_pressed("kick") or kick_cooldown > 0:
		return
	
	var balls = kick_area.get_overlapping_bodies()
	for body in balls:
		if body.is_in_group("ball"):
			# Determinar tipo de chute
			var kick_type = determine_kick_type()
			
			# Calcular física avançada
			var kick_data = physics_controller.calculate_advanced_kick(
				self, body, input_vector, kick_type
			)
			
			# Aplicar força e efeitos
			body.receive_kick(kick_data.force, global_position)
			
			if kick_data.spin != 0:
				body.angular_velocity += kick_data.spin
			
			# Efeitos visuais por tipo
			create_kick_effects(kick_type, kick_data.effects)
			
			# Som com variação
			if audio_system:
				audio_system.play_kick_sound(kick_data.force.length(), global_position)
			
			# Feedback háptico
			if "device" in input_map:
				audio_system.play_impact_haptic(input_map.device, charge_power)
			
			# Combo
			combo_count += 1
			combo_timer = 2.0
			
			kick_cooldown = GameConstants.KICK_COOLDOWN
			charge_power = 0.0
			break

func determine_kick_type() -> AdvancedPhysicsController.KickType:
	# Power shot
	if charge_power > 0.8:
		return AdvancedPhysicsController.KickType.POWER
	
	# Chip shot
	if input_vector.y < -0.7:
		return AdvancedPhysicsController.KickType.CHIP
	
	# Curve shots
	if abs(input_vector.x) > 0.7:
		if input_vector.x > 0:
			return AdvancedPhysicsController.KickType.CURVE_RIGHT
		else:
			return AdvancedPhysicsController.KickType.CURVE_LEFT
	
	# Aerial shots
	if not is_on_floor():
		if velocity.y < -200:
			return AdvancedPhysicsController.KickType.BICYCLE
		elif current_height > 50:
			return AdvancedPhysicsController.KickType.HEADER
		else:
			return AdvancedPhysicsController.KickType.VOLLEY
	
	return AdvancedPhysicsController.KickType.NORMAL

func create_kick_effects(kick_type: AdvancedPhysicsController.KickType, effects: Array):
	# Efeitos base
	modulate = Color.WHITE * 1.5
	create_tween().tween_property(self, "modulate", player_color, 0.1)
	
	# Efeitos específicos por tipo
	match kick_type:
		AdvancedPhysicsController.KickType.POWER:
			# Explosão de poder
			if effects_manager:
				effects_manager.create_shockwave(global_position, 2.0)
			# Shake da câmera
			if get_viewport().get_camera_2d():
				effects_manager.camera_shake(get_viewport().get_camera_2d(), 0.2, 5.0)
				
		AdvancedPhysicsController.KickType.BICYCLE:
			# Rotação completa
			var tween = create_tween()
			tween.tween_property(self, "rotation", rotation + TAU, 0.5)
			
	# Mostrar combo
	if combo_count > 1:
		show_combo_text()

func update_stamina(delta):
	if is_sprinting and velocity.length() > 100:
		stamina -= 20.0 * delta / player_stats.stamina
	else:
		stamina += stamina_regen_rate * delta * player_stats.stamina
	
	stamina = clamp(stamina, 0.0, 100.0)
	
	# Efeitos de stamina baixa
	if stamina < 20.0:
		# Reduzir velocidade máxima
		velocity *= 0.9
		# Visual de cansaço
		sprite.modulate = player_color * 0.8

func update_combos(delta):
	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_count = 0

func show_combo_text():
	var combo_label = Label.new()
	combo_label.text = "x%d COMBO!" % combo_count
	combo_label.add_theme_font_size_override("font_size", 24 + combo_count * 4)
	combo_label.modulate = player_color
	combo_label.position = Vector2(-50, -80)
	add_child(combo_label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_label, "position:y", -120, 0.5)
	tween.tween_property(combo_label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(combo_label.queue_free)

func update_advanced_visuals(delta):
	# Altura visual (para saltos)
	if not is_on_floor():
		current_height = abs(velocity.y) * 0.1
		squash_stretch = Vector2(0.9, 1.1)
	else:
		current_height = move_toward(current_height, 0.0, 100 * delta)
		squash_stretch = squash_stretch.lerp(Vector2.ONE, 10 * delta)
	
	# Aplicar transformações
	sprite.scale = squash_stretch
	sprite.position.y = -current_height
	
	# Trail de velocidade
	update_speed_trail()
	
	# Sombra dinâmica
	if shadow:
		shadow.scale = Vector2.ONE * (1.0 - current_height * 0.002)
		shadow.modulate.a = 0.5 * (1.0 - current_height * 0.005)
	
	# Partículas de boost
	if boost_particles:
		boost_particles.emitting = is_sprinting and velocity.length() > 300
	
	# Indicador de carga
	if is_charging_shot:
		update_charge_indicator()

func update_speed_trail():
	if velocity.length() > 300:
		trail.add_point(global_position)
		if trail.get_point_count() > 10:
			trail.remove_point(0)
		
		# Cor baseada na velocidade
		var speed_ratio = velocity.length() / GameConstants.PLAYER_SPRINT_SPEED
		trail.gradient = create_speed_gradient(speed_ratio)
	else:
		trail.clear_points()

func create_speed_gradient(speed_ratio: float) -> Gradient:
	var gradient = Gradient.new()
	var color = player_color
	gradient.add_point(0.0, Color(color.r, color.g, color.b, 0))
	gradient.add_point(0.5, Color(color.r, color.g, color.b, speed_ratio * 0.5))
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 0))
	return gradient

func update_charge_indicator():
	if not skill_indicator:
		return
	
	skill_indicator.visible = true
	skill_indicator.scale = Vector2.ONE * (1.0 + charge_power * 0.5)
	skill_indicator.modulate.a = charge_power
	skill_indicator.rotation += 0.1

func create_skill_indicator():
	skill_indicator = Sprite2D.new()
	# Criar textura circular
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x - 32, y - 32).length()
			if dist < 30 and dist > 25:
				image.set_pixel(x, y, Color.WHITE)
	
	skill_indicator.texture = ImageTexture.create_from_image(image)
	skill_indicator.visible = false
	skill_indicator.position.y = -60
	add_child(skill_indicator)

func update_audio_feedback():
	if not audio_system:
		return
	
	# Passos
	if is_on_floor() and velocity.length() > 50:
		if not has_meta("last_footstep") or Time.get_ticks_msec() - get_meta("last_footstep") > 300:
			audio_system.play_footstep(global_position, velocity.length())
			set_meta("last_footstep", Time.get_ticks_msec())
	
	# Som de sprint
	if is_sprinting and velocity.length() > 300:
		# Adicionar som de vento/velocidade
		pass

func celebrate_goal():
	advanced_state = AdvancedState.CELEBRATING
	
	# Animação elaborada
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "rotation", TAU, 0.5)
	tween.parallel().tween_property(self, "position:y", position.y - 50, 0.25)
	tween.tween_property(self, "position:y", position.y, 0.25)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.tween_property(self, "rotation", 0, 0.1)
	tween.tween_callback(func(): advanced_state = AdvancedState.NORMAL)
	
	# Efeitos visuais
	if effects_manager:
		effects_manager.create_boost_effect(self)