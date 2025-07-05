extends Node

# Gerenciador centralizado de efeitos visuais 2.5D

class_name VisualEffectsManager

# Shaders e materiais
var grass_shader: Shader
var ball_trail_material: ShaderMaterial
var player_shadow_texture: Texture2D

# Pools de objetos para performance
var particle_pool := []
var trail_pool := []
var impact_pool := []

func _ready():
	# Pré-carregar recursos
	setup_shaders()
	setup_particle_pools()

func setup_shaders():
	# Shader do campo com perspectiva
	grass_shader = create_grass_shader()
	
	# Material do trail da bola
	ball_trail_material = ShaderMaterial.new()
	ball_trail_material.shader = create_trail_shader()

func create_grass_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float perspective_amount : hint_range(0.0, 1.0) = 0.3;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);
uniform float line_width : hint_range(0.0, 0.1) = 0.01;
uniform sampler2D grass_texture;
uniform float time_scale = 0.5;

void fragment() {
    vec2 uv = UV;
    
    // Distorção de perspectiva
    float perspective = mix(1.0, 0.7, uv.y * perspective_amount);
    uv.x = (uv.x - 0.5) * perspective + 0.5;
    
    // Cor base do campo com textura
    vec3 grass_color = texture(grass_texture, uv * vec2(10.0, 15.0)).rgb;
    
    // Variação de cor (faixas de grama)
    float stripe = sin(uv.y * 30.0) * 0.03;
    grass_color += stripe;
    
    // Movimento sutil da grama
    float wind = sin(TIME * time_scale + uv.x * 10.0) * 0.01;
    grass_color += wind;
    
    // Linhas do campo
    float center_line = smoothstep(0.495, 0.5, uv.x) * smoothstep(0.505, 0.5, uv.x);
    float circle = length(uv - vec2(0.5, 0.5));
    float center_circle = smoothstep(0.145, 0.15, circle) * smoothstep(0.155, 0.15, circle);
    
    // Áreas dos gols
    float goal_area_left = smoothstep(0.0, 0.15, uv.x) * 
                          smoothstep(0.35, 0.4, abs(uv.y - 0.5));
    float goal_area_right = smoothstep(0.85, 1.0, uv.x) * 
                           smoothstep(0.35, 0.4, abs(uv.y - 0.5));
    
    // Combinar
    vec3 final_color = grass_color;
    final_color = mix(final_color, line_color.rgb, (center_line + center_circle) * line_color.a);
    final_color = mix(final_color, line_color.rgb, (goal_area_left + goal_area_right) * line_color.a * 0.5);
    
    // Escurecer no topo (distância) e clarear no centro
    float distance_fade = mix(0.7, 1.0, uv.y);
    float center_highlight = 1.0 + smoothstep(0.3, 0.0, length(uv - vec2(0.5, 0.5))) * 0.1;
    
    final_color *= distance_fade * center_highlight;
    
    // Vinheta suave
    float vignette = smoothstep(0.0, 0.5, min(uv.x, 1.0 - uv.x) * min(uv.y, 1.0 - uv.y));
    final_color *= 0.8 + vignette * 0.2;
    
    COLOR = vec4(final_color, 1.0);
}
"""
	return shader

func create_trail_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 trail_color : source_color = vec4(1.0, 1.0, 0.5, 0.5);
uniform float fade_speed = 2.0;
uniform float distortion = 0.1;

void fragment() {
    vec2 uv = UV;
    
    // Distorção ondulada
    uv.y += sin(uv.x * 10.0 + TIME * 5.0) * distortion;
    
    // Gradiente de fade
    float alpha = (1.0 - uv.x) * trail_color.a;
    alpha *= smoothstep(0.0, 0.1, uv.y) * smoothstep(1.0, 0.9, uv.y);
    
    // Cor com brilho
    vec3 color = trail_color.rgb;
    color += vec3(0.2, 0.2, 0.0) * (1.0 - uv.x);
    
    COLOR = vec4(color, alpha);
}
"""
	return shader

func setup_particle_pools():
	# Criar pools de partículas reutilizáveis
	for i in range(20):
		var particles = CPUParticles2D.new()
		particles.emitting = false
		particles.amount = 30
		particles.lifetime = 0.5
		particles.one_shot = true
		particle_pool.append(particles)
		add_child(particles)

# Efeitos de impacto da bola
func create_ball_impact(position: Vector2, velocity: Vector2, color: Color = Color.WHITE):
	var particles = get_free_particle()
	if not particles:
		return
	
	particles.position = position
	particles.direction = -velocity.normalized()
	particles.initial_velocity_min = velocity.length() * 0.3
	particles.initial_velocity_max = velocity.length() * 0.5
	particles.spread = 45.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = color
	
	# Gradiente
	var gradient = Gradient.new()
	gradient.add_point(0.0, color)
	gradient.add_point(0.5, color * 1.5)
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 0))
	particles.color_ramp = gradient
	
	particles.emitting = true
	
	# Ondas de choque
	create_shockwave(position, velocity.length() * 0.1)

func create_shockwave(position: Vector2, strength: float):
	var shockwave = Sprite2D.new()
	shockwave.texture = preload("res://assets/shockwave.png") # Criar uma textura circular com gradiente
	shockwave.modulate.a = 0.5
	shockwave.scale = Vector2.ZERO
	get_parent().add_child(shockwave)
	shockwave.global_position = position
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shockwave, "scale", Vector2.ONE * strength, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(shockwave.queue_free)

# Trail dinâmico da bola
func create_ball_trail(ball: RigidBody2D) -> Line2D:
	var trail = Line2D.new()
	trail.width = 20.0
	trail.width_curve = Curve.new()
	trail.width_curve.add_point(Vector2(0, 1))
	trail.width_curve.add_point(Vector2(1, 0))
	
	# Gradiente de cor
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0.5, 0))
	gradient.add_point(0.3, Color(1, 1, 0.8, 0.8))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	trail.gradient = gradient
	
	trail.z_index = -1
	return trail

# Sombras dinâmicas
func create_dynamic_shadow(parent: Node2D, offset_y: float = 24) -> Sprite2D:
	var shadow = Sprite2D.new()
	shadow.texture = create_shadow_texture()
	shadow.modulate = Color(0, 0, 0, 0.5)
	shadow.position.y = offset_y
	shadow.z_index = -2
	parent.add_child(shadow)
	return shadow

func create_shadow_texture() -> ImageTexture:
	var image = Image.create(64, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	# Desenhar elipse
	for x in range(64):
		for y in range(32):
			var dx = (x - 32.0) / 32.0
			var dy = (y - 16.0) / 16.0
			var dist = sqrt(dx * dx + dy * dy)
			if dist < 1.0:
				var alpha = 1.0 - dist
				image.set_pixel(x, y, Color(0, 0, 0, alpha * 0.5))
	
	return ImageTexture.create_from_image(image)

# Efeito de power-up/boost
func create_boost_effect(player: CharacterBody2D):
	var boost_particles = CPUParticles2D.new()
	boost_particles.amount = 50
	boost_particles.lifetime = 0.3
	boost_particles.speed_scale = 2.0
	boost_particles.direction = Vector2.UP
	boost_particles.spread = 20.0
	boost_particles.initial_velocity_min = 100.0
	boost_particles.initial_velocity_max = 200.0
	boost_particles.scale_amount_min = 0.5
	boost_particles.scale_amount_max = 1.0
	boost_particles.color = Color(0.5, 0.8, 1.0)
	
	player.add_child(boost_particles)
	boost_particles.position = Vector2(0, 20)
	boost_particles.emitting = true
	
	# Auto-destruir
	await boost_particles.finished
	boost_particles.queue_free()

# Distorção de calor/velocidade
func create_speed_distortion(player: CharacterBody2D):
	var distortion = ColorRect.new()
	distortion.size = Vector2(60, 80)
	distortion.position = Vector2(-30, -40)
	distortion.color = Color(1, 1, 1, 0.3)
	distortion.material = ShaderMaterial.new()
	distortion.material.shader = create_distortion_shader()
	
	player.add_child(distortion)
	distortion.z_index = 1
	
	# Fade in/out baseado na velocidade
	return distortion

func create_distortion_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float distortion_strength = 0.02;
uniform float speed = 5.0;

void fragment() {
    vec2 uv = UV;
    
    // Ondas de distorção
    float wave1 = sin(uv.y * 10.0 + TIME * speed) * distortion_strength;
    float wave2 = cos(uv.x * 8.0 + TIME * speed * 1.3) * distortion_strength;
    
    uv += vec2(wave1, wave2);
    
    // Fade nas bordas
    float edge_fade = smoothstep(0.0, 0.2, uv.x) * smoothstep(1.0, 0.8, uv.x);
    edge_fade *= smoothstep(0.0, 0.2, uv.y) * smoothstep(1.0, 0.8, uv.y);
    
    COLOR = vec4(1.0, 1.0, 1.0, edge_fade * 0.3);
}
"""
	return shader

func get_free_particle() -> CPUParticles2D:
	for p in particle_pool:
		if not p.emitting:
			return p
	return null

# Efeito de gol épico
func create_epic_goal_effect(goal_position: Vector2, scoring_team: int):
	# Câmera shake
	if get_viewport().get_camera_2d():
		camera_shake(get_viewport().get_camera_2d(), 0.5, 10.0)
	
	# Explosão de partículas em círculo
	for i in range(8):
		var angle = i * TAU / 8
		var offset = Vector2(cos(angle), sin(angle)) * 50
		create_ball_impact(goal_position + offset, -offset * 5, PlayerManager.PLAYER_COLORS[scoring_team * 2])
	
	# Raios de luz
	var rays = Node2D.new()
	get_parent().add_child(rays)
	rays.global_position = goal_position
	
	for i in range(12):
		var ray = ColorRect.new()
		ray.size = Vector2(500, 5)
		ray.position = Vector2(-250, -2.5)
		ray.rotation = i * TAU / 12
		ray.color = PlayerManager.PLAYER_COLORS[scoring_team * 2]
		ray.color.a = 0.0
		rays.add_child(ray)
		
		var tween = create_tween()
		tween.tween_property(ray, "color:a", 0.5, 0.1)
		tween.tween_property(ray, "color:a", 0.0, 0.4)
	
	# Auto-limpar
	await get_tree().create_timer(0.5).timeout
	rays.queue_free()

func camera_shake(camera: Camera2D, duration: float, strength: float):
	var original_pos = camera.position
	var elapsed = 0.0
	
	while elapsed < duration:
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		camera.position = original_pos + offset
		
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		strength *= 0.9 # Decay
	
	camera.position = original_pos