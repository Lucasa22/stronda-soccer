extends Node2D

# Este script constrói a arena programaticamente
# Útil para prototipagem rápida sem precisar criar cenas manualmente

func _ready():
	build_arena()

func build_arena():
	# Criar fundo
	create_background()
	
	# Criar paredes
	create_walls()
	
	# Criar gols
	create_goals()
	
	# Criar marcações do campo
	create_field_markings()

func create_background():
	var background = ColorRect.new()
	background.color = Color(0.1, 0.5, 0.2) # Verde grama
	background.size = Vector2(GameConstants.FIELD_WIDTH, GameConstants.FIELD_HEIGHT)
	background.position = Vector2.ZERO
	background.z_index = -10
	add_child(background)

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
		Vector2(-GameConstants.WALL_THICKNESS / 2, GameConstants.FIELD_HEIGHT / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH / 2)
	)
	create_wall(
		Vector2(-GameConstants.WALL_THICKNESS / 2, 3 * GameConstants.FIELD_HEIGHT / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH / 2)
	)
	
	# Parede direita (com abertura para gol)
	create_wall(
		Vector2(GameConstants.FIELD_WIDTH + GameConstants.WALL_THICKNESS / 2, GameConstants.FIELD_HEIGHT / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH / 2)
	)
	create_wall(
		Vector2(GameConstants.FIELD_WIDTH + GameConstants.WALL_THICKNESS / 2, 3 * GameConstants.FIELD_HEIGHT / 4),
		Vector2(GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2 - GameConstants.GOAL_WIDTH / 2)
	)

func create_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.position = pos
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	
	# Visual
	var visual = ColorRect.new()
	visual.color = Color(0.3, 0.3, 0.3)
	visual.size = size
	visual.position = -size / 2
	wall.add_child(visual)
	
	# Configurar camadas
	wall.collision_layer = GameConstants.LAYER_WALLS
	
	add_child(wall)

func create_goals():
	# Gol esquerdo
	create_goal(
		Vector2(-GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2),
		1
	)
	
	# Gol direito
	create_goal(
		Vector2(GameConstants.FIELD_WIDTH + GameConstants.WALL_THICKNESS, GameConstants.FIELD_HEIGHT / 2),
		2
	)

func create_goal(pos: Vector2, team: int):
	var goal = Area2D.new()
	goal.position = pos
	goal.add_to_group("goal")
	goal.set_meta("team", team)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(GameConstants.WALL_THICKNESS * 2, GameConstants.GOAL_WIDTH)
	collision.shape = shape
	goal.add_child(collision)
	
	# Visual
	var visual = ColorRect.new()
	visual.color = Color(1, 1, 1, 0.3)
	visual.size = shape.size
	visual.position = -shape.size / 2
	goal.add_child(visual)
	
	# Configurar camadas
	goal.collision_layer = GameConstants.LAYER_GOALS
	goal.collision_mask = GameConstants.LAYER_BALL
	
	# Conectar sinal para detectar gols
	goal.body_entered.connect(_on_goal_entered.bind(team))
	
	add_child(goal)

func _on_goal_entered(body: Node2D, team: int):
	if body.is_in_group("ball"):
		# Notificar o jogo principal
		if get_parent().has_method("on_goal_scored"):
			get_parent().on_goal_scored(3 - team) # Inverter time (gol contra)

func create_field_markings():
	# Linha central
	var center_line = Line2D.new()
	center_line.add_point(Vector2(GameConstants.FIELD_WIDTH / 2, 0))
	center_line.add_point(Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT))
	center_line.width = 3.0
	center_line.default_color = Color(1, 1, 1, 0.5)
	center_line.z_index = -5
	add_child(center_line)
	
	# Círculo central
	var center_circle = Line2D.new()
	var radius = 100.0
	var points = 32
	for i in range(points + 1):
		var angle = i * TAU / points
		var point = Vector2(cos(angle), sin(angle)) * radius
		center_circle.add_point(Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT / 2) + point)
	center_circle.width = 3.0
	center_circle.default_color = Color(1, 1, 1, 0.5)
	center_circle.z_index = -5
	add_child(center_circle)
	
	# Áreas dos gols
	create_goal_area(Vector2(0, GameConstants.FIELD_HEIGHT / 2), false)
	create_goal_area(Vector2(GameConstants.FIELD_WIDTH, GameConstants.FIELD_HEIGHT / 2), true)

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
	
	area.width = 3.0
	area.default_color = Color(1, 1, 1, 0.5)
	area.z_index = -5
	add_child(area)
