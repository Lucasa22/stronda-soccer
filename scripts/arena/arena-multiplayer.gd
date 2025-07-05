extends Node2D

# Sinal emitido quando um gol é marcado
signal goal_scored(scoring_team: int, scoring_player: Node)

# Referências
var left_goal: Area2D
var right_goal: Area2D

func _ready():
	build_arena()

func build_arena():
	# Criar fundo
	create_background()
	
	# Criar paredes
	create_walls()
	
	# Criar gols com detecção melhorada
	create_goals()
	
	# Criar marcações do campo
	create_field_markings()
	
	# Efeitos visuais extras
	create_visual_effects()

func create_background():
	var background = ColorRect.new()
	background.color = Color(0.1, 0.5, 0.2) # Verde grama
	background.size = Vector2(GameConstants.FIELD_WIDTH, GameConstants.FIELD_HEIGHT)
	background.position = Vector2.ZERO
	background.z_index = -10
	add_child(background)
	
	# Adicionar textura de grama (padrão)
	var grass_pattern = ColorRect.new()
	grass_pattern.color = Color(0.08, 0.45, 0.18, 0.3)
	grass_pattern.size = Vector2(GameConstants.FIELD_WIDTH, GameConstants.FIELD_HEIGHT)
	grass_pattern.position = Vector2.ZERO
	grass_pattern.z_index = -9
	
	# Criar padrão de linhas
	for i in range(0, int(GameConstants.FIELD_HEIGHT), 40):
		var line = ColorRect.new()
		line.color = Color(0.12, 0.55, 0.22, 0.5)
		line.size = Vector2(GameConstants.FIELD_WIDTH, 20)
		line.position = Vector2(0, i)
		grass_pattern.add_child(line)
	
	add_child(grass_pattern)

func create_walls():
	# Parede superior
	create_wall(
		Vector2(GameConstants.FIELD_WIDTH / 2, -GameConstants.WALL_THICKNESS / 2),
		Vector2(GameConstants.FIELD_WIDTH, GameConstants.WALL_THICKNESS)
	)
	
	# Parede inferior
	create_wall(
		Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT + GameConstants.WALL_THICKNESS / 2),
		Vector2(GameConstants.FIELD_WIDTH, GameConstants.WALL_THICKNESS)
	)
	
	# Parede esquerda (com abertura para gol)
	create_wall(
		Vector2(-GameConstants.WALL_THICKNESS / 2, GameConstants.FIELD_HEIGHT / 4 - GameConstants.GOAL_WIDTH / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH)
	)
	create_wall(
		Vector2(-GameConstants.WALL_THICKNESS / 2, 3 * GameConstants.FIELD_HEIGHT / 4 + GameConstants.GOAL_WIDTH / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH)
	)
	
	# Parede direita (com abertura para gol)
	create_wall(
		Vector2(GameConstants.FIELD_WIDTH + GameConstants.WALL_THICKNESS / 2, GameConstants.FIELD_HEIGHT / 4 - GameConstants.GOAL_WIDTH / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH)
	)
	create_wall(
		Vector2(GameConstants.FIELD_WIDTH + GameConstants.WALL_THICKNESS / 2, 3 * GameConstants.FIELD_HEIGHT / 4 + GameConstants.GOAL_WIDTH / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH)
	)

func create_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.position = pos
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	
	# Visual melhorado
	var visual = ColorRect.new()
	visual.color = Color(0.2, 0.2, 0.2)
	visual.size = size
	visual.position = -size / 2
	wall.add_child(visual)
	
	# Borda clara
	var border = ColorRect.new()
	border.color = Color(0.4, 0.4, 0.4)
	border.size = Vector2(size.x - 4, size.y - 4)
	border.position = -size / 2 + Vector2(2, 2)
	wall.add_child(border)
	
	# Configurar camadas
	wall.collision_layer = GameConstants.LAYER_WALLS
	wall.collision_mask = GameConstants.LAYER_BALL | GameConstants.LAYER_PLAYERS
	
	add_child(wall)

func create_goals():
	# Gol esquerdo (Time 2 defende)
	left_goal = create_goal(
		Vector2(-GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2),
		1  # Time 2 defende este gol
	)
	
	# Gol direito (Time 1 defende)
	right_goal = create_goal(
		Vector2(GameConstants.FIELD_WIDTH + GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2),
		0  # Time 1 defende este gol
	)

func create_goal(pos: Vector2, defending_team: int) -> Area2D:
	var goal = Area2D.new()
	goal.position = pos
	goal.add_to_group("goal")
	goal.set_meta("defending_team", defending_team)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(GameConstants.WALL_THICKNESS * 3, GameConstants.GOAL_WIDTH)
	collision.shape = shape
	goal.add_child(collision)
	
	# Visual da rede do gol
	var net = ColorRect.new()
	net.color = Color(0.8, 0.8, 0.8, 0.3)
	net.size = shape.size
	net.position = -shape.size / 2
	goal.add_child(net)
	
	# Padrão de rede
	for i in range(0, int(shape.size.x), 10):
		var line = ColorRect.new()
		line.color = Color(0.6, 0.6, 0.6, 0.5)
		line.size = Vector2(1, shape.size.y)
		line.position = Vector2(i - shape.size.x / 2, -shape.size.y / 2)
		goal.add_child(line)
	
	for i in range(0, int(shape.size.y), 10):
		var line = ColorRect.new()
		line.color = Color(0.6, 0.6, 0.6, 0.5)
		line.size = Vector2(shape.size.x, 1)
		line.position = Vector2(-shape.size.x / 2, i - shape.size.y / 2)
		goal.add_child(line)
	
	# Poste superior e inferior
	var post_top = ColorRect.new()
	post_top.color = Color(0.9, 0.9, 0.9)
	post_top.size = Vector2(8, 8)
	post_top.position = Vector2(-4, -GameConstants.GOAL_WIDTH / 2 - 4)
	goal.add_child(post_top)
	
	var post_bottom = post_top.duplicate()
	post_bottom.position = Vector2(-4, GameConstants.GOAL_WIDTH / 2 - 4)
	goal.add_child(post_bottom)
	
	# Configurar camadas
	goal.collision_layer = GameConstants.LAYER_GOALS
	goal.collision_mask = GameConstants.LAYER_BALL
	goal.monitorable = true
	goal.monitoring = true
	
	# Conectar sinal para detectar gols
	goal.body_entered.connect(_on_goal_entered.bind(defending_team))
	
	add_child(goal)
	return goal

func _on_goal_entered(body: Node2D, defending_team: int):
	if body.is_in_group("ball"):
		# O time que marcou é o oposto do que defende
		var scoring_team = 1 - defending_team
		
		# Encontrar quem foi o último a tocar na bola
		var scoring_player = null
		if body.has_property("last_touched_by"):
			scoring_player = body.last_touched_by
		
		# Emitir sinal de gol
		goal_scored.emit(scoring_team, scoring_player)
		
		# Efeitos visuais do gol
		create_goal_effects(body.global_position, scoring_team)

func create_goal_effects(pos: Vector2, team: int):
	# Explosão de partículas
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 50
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.speed_scale = 2.0
	particles.explosion_ratio = 1.0
	particles.spread = 45.0
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 400.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 2.0
	
	# Cor baseada no time
	var team_color = PlayerManager.PLAYER_COLORS[team * 2]
	particles.color = team_color
	
	# Gradiente de fade out
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.WHITE)
	gradient.add_point(0.5, team_color)
	gradient.add_point(1.0, Color(team_color.r, team_color.g, team_color.b, 0))
	particles.color_ramp = gradient
	
	add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	
	# Flash na tela
	var flash = ColorRect.new()
	flash.color = Color(team_color.r, team_color.g, team_color.b, 0.3)
	flash.size = Vector2(GameConstants.FIELD_WIDTH, GameConstants.FIELD_HEIGHT)
	flash.position = Vector2.ZERO
	flash.z_index = 100
	add_child(flash)
	
	# Fade out do flash
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
	
	# Auto-destruir partículas
	await particles.finished
	particles.queue_free()

func create_field_markings():
	# Linha central
	var center_line = Line2D.new()
	center_line.add_point(Vector2(GameConstants.FIELD_WIDTH / 2, 0))
	center_line.add_point(Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT))
	center_line.width = 4.0
	center_line.default_color = Color(1, 1, 1, 0.6)
	center_line.z_index = -5
	add_child(center_line)
	
	# Círculo central
	create_circle(Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT / 2), 100.0)
	
	# Ponto central
	var center_dot = ColorRect.new()
	center_dot.color = Color(1, 1, 1, 0.8)
	center_dot.size = Vector2(8, 8)
	center_dot.position = Vector2(GameConstants.FIELD_WIDTH / 2 - 4, GameConstants.FIELD_HEIGHT / 2 - 4)
	center_dot.z_index = -5
	add_child(center_dot)
	
	# Áreas dos gols
	create_goal_area(Vector2(0, GameConstants.FIELD_HEIGHT / 2), false)
	create_goal_area(Vector2(GameConstants.FIELD_WIDTH, GameConstants.FIELD_HEIGHT / 2), true)

func create_circle(center: Vector2, radius: float):
	var circle = Line2D.new()
	var points = 64
	for i in range(points + 1):
		var angle = i * TAU / points
		var point = Vector2(cos(angle), sin(angle)) * radius
		circle.add_point(center + point)
	circle.width = 4.0
	circle.default_color = Color(1, 1, 1, 0.6)
	circle.z_index = -5
	add_child(circle)

func create_goal_area(pos: Vector2, right_side: bool):
	var area = Line2D.new()
	var width = 150.0
	var height = 200.0
	
	var points = []
	if right_side:
		points.append(pos + Vector2(0, -height/2))
		points.append(pos + Vector2(-width, -height/2))
		points.append(pos + Vector2(-width, height/2))
		points.append(pos + Vector2(0, height/2))
	else:
		points.append(pos + Vector2(0, -height/2))
		points.append(pos + Vector2(width, -height/2))
		points.append(pos + Vector2(width, height/2))
		points.append(pos + Vector2(0, height/2))
	
	for point in points:
		area.add_point(point)
	
	area.width = 4.0
	area.default_color = Color(1, 1, 1, 0.6)
	area.z_index = -5
	add_child(area)
	
	# Semicírculo da pequena área
	var semi_center = pos + Vector2(-width if right_side else width, 0)
	create_semicircle(semi_center, 50.0, right_side)

func create_semicircle(center: Vector2, radius: float, right_side: bool):
	var semicircle = Line2D.new()
	var points = 32
	var start_angle = -PI/2 if right_side else PI/2
	var end_angle = PI/2 if right_side else 3*PI/2
	
	for i in range(points + 1):
		var t = float(i) / float(points)
		var angle = lerp(start_angle, end_angle, t)
		var point = Vector2(cos(angle), sin(angle)) * radius
		semicircle.add_point(center + point)
	
	semicircle.width = 4.0
	semicircle.default_color = Color(1, 1, 1, 0.6)
	semicircle.z_index = -5
	add_child(semicircle)

func create_visual_effects():
	# Adicionar sombras suaves nas bordas do campo
	for i in range(4):
		var shadow = ColorRect.new()
		shadow.color = Color(0, 0, 0, 0.2 - i * 0.05)
		shadow.z_index = -8
		
		match i:
			0: # Superior
				shadow.size = Vector2(GameConstants.FIELD_WIDTH, 20)
				shadow.position = Vector2(0, 0)
			1: # Inferior
				shadow.size = Vector2(GameConstants.FIELD_WIDTH, 20)
				shadow.position = Vector2(0, GameConstants.FIELD_HEIGHT - 20)
			2: # Esquerda
				shadow.size = Vector2(20, GameConstants.FIELD_HEIGHT)
				shadow.position = Vector2(0, 0)
			3: # Direita
				shadow.size = Vector2(20, GameConstants.FIELD_HEIGHT)
				shadow.position = Vector2(GameConstants.FIELD_WIDTH - 20, 0)
		
		add_child(shadow)